from pathlib import Path
from typing import Tuple

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db.database import get_db
from app.models.models import Category, Course, Lesson, Module, User
from app.api.routes.auth import get_current_user
from app.schemas.schemas import ScanResult

router = APIRouter()

def _get_or_create_category(db: Session, name: str) -> Tuple[Category, bool]:
    category = db.query(Category).filter(Category.name == name).first()
    created = False
    if not category:
        category = Category(name=name, icon="📂", description=f"Imported from {name}")
        db.add(category)
        db.flush()
        created = True
    return category, created

def _extension_to_type(path: Path) -> str:
    ext = path.suffix.lower().lstrip(".")
    if ext in {"mp4", "mov", "mkv"}:
        return "video"
    if ext in {"mp3", "wav"}:
        return "audio"
    if ext in {"pdf"}:
        return "pdf"
    return ext or "file"

def _scan_directory(
    db: Session,
    course: Course,
    parent_module_id: int,
    current_path: Path,
    order_start: int,
):
    module_order = order_start
    lesson_count = 0
    modules_created = 0
    lessons_created = 0

    for entry in sorted(current_path.iterdir(), key=lambda p: (p.is_file(), p.name.lower())):
        if entry.is_dir():
            module = Module(
                course_id=course.id,
                title=entry.name,
                order=module_order,
                parent_id=parent_module_id,
                file_path=str(entry),
            )
            db.add(module)
            db.flush()
            modules_created += 1
            module_order += 1

            m_count, mo_created, l_created = _scan_directory(
                db, course, module.id, entry, 1
            )
            lesson_count += m_count
            modules_created += mo_created
            lessons_created += l_created
        else:
            lesson = Lesson(
                module_id=parent_module_id,
                title=entry.stem,
                file_type=_extension_to_type(entry),
                file_path=str(entry),
                file_size=entry.stat().st_size,
                order=module_order,
            )
            db.add(lesson)
            lessons_created += 1
            lesson_count += 1
            module_order += 1

    return lesson_count, modules_created, lessons_created

@router.post("/scan", response_model=ScanResult)
def scan_courses(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    root = Path(settings.COURSES_ROOT_PATH)
    if not root.exists() or not root.is_dir():
        raise HTTPException(status_code=400, detail=f"COURSES_ROOT_PATH not found: {root}")

    courses_created = courses_updated = modules_created = lessons_created = categories_created = 0

    for category_dir in sorted([p for p in root.iterdir() if p.is_dir()]):
        category, cat_created = _get_or_create_category(db, category_dir.name)
        categories_created += 1 if cat_created else 0

        for course_dir in sorted([p for p in category_dir.iterdir() if p.is_dir()]):
            course = (
                db.query(Course)
                .filter(Course.file_path == str(course_dir))
                .first()
            )

            if not course:
                course = Course(
                    title=course_dir.name,
                    description=f"Imported from {course_dir}",
                    category_id=category.id,
                    file_path=str(course_dir),
                    total_lessons=0,
                    total_duration=0,
                )
                db.add(course)
                db.flush()
                courses_created += 1
            else:
                course.category_id = category.id
                course.file_path = str(course_dir)
                courses_updated += 1

            # Clear existing structure for this course
            db.query(Lesson).filter(
                Lesson.module_id.in_(
                    db.query(Module.id).filter(Module.course_id == course.id)
                )
            ).delete(synchronize_session=False)
            db.query(Module).filter(Module.course_id == course.id).delete(synchronize_session=False)
            db.flush()

            # Root module mirrors course folder
            root_module = Module(
                course_id=course.id,
                title=course.title,
                order=0,
                parent_id=None,
                file_path=str(course_dir),
            )
            db.add(root_module)
            db.flush()
            modules_created += 1

            lesson_count, mo_created, le_created = _scan_directory(
                db, course, root_module.id, course_dir, 1
            )
            modules_created += mo_created
            lessons_created += le_created
            course.total_lessons = lesson_count
            course.total_duration = 0  # Media duration not calculated here

    db.commit()

    return ScanResult(
        success=True,
        message="Scan completed",
        courses_created=courses_created,
        courses_updated=courses_updated,
        modules_created=modules_created,
        lessons_created=lessons_created,
        categories_created=categories_created,
    )
