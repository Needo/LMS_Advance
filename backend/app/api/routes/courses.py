from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.db.database import get_db
from app.models.models import Course, Module, Lesson, User, Category
from app.schemas.schemas import (
    Course as CourseSchema,
    CourseBase,
    CourseTree,
    ModuleNode,
    LessonNode,
)
from app.api.routes.auth import get_current_user
from fastapi import Body

router = APIRouter()

@router.get("/", response_model=List[CourseSchema])
def get_all_courses(db: Session = Depends(get_db)):
    courses = db.query(Course).all()
    return courses

@router.get("/category/{category_id}", response_model=List[CourseSchema])
def get_courses_by_category(category_id: int, db: Session = Depends(get_db)):
    courses = db.query(Course).filter(Course.category_id == category_id).all()
    return courses

@router.get("/{course_id}", response_model=CourseSchema)
def get_course(course_id: int, db: Session = Depends(get_db)):
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")
    return course

@router.patch("/{course_id}/category", response_model=CourseSchema)
def update_course_category(
    course_id: int,
    payload: dict = Body(...),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not enough permissions")

    category_id = payload.get("category_id")
    course = db.query(Course).filter(Course.id == course_id).first()
    if not course:
        raise HTTPException(status_code=404, detail="Course not found")

    if category_id is not None:
        category = db.query(Category).filter(Category.id == category_id).first()
        if not category:
            raise HTTPException(status_code=404, detail="Category not found")
        course.category_id = category_id

    db.commit()
    db.refresh(course)
    return course

@router.get("/tree", response_model=List[CourseTree])
def get_course_tree(db: Session = Depends(get_db)):
    courses = db.query(Course).all()

    def build_module_node(module: Module) -> ModuleNode:
        return ModuleNode(
            id=module.id,
            title=module.title,
            order=module.order,
            file_path=module.file_path,
            lessons=[
                LessonNode(
                    id=lesson.id,
                    title=lesson.title,
                    file_type=lesson.file_type,
                    file_path=lesson.file_path,
                    order=lesson.order,
                    duration=lesson.duration,
                )
                for lesson in sorted(module.lessons, key=lambda l: l.order)
            ],
            children=[
                build_module_node(child)
                for child in sorted(module.children, key=lambda m: m.order)
            ],
        )

    tree: List[CourseTree] = []
    for course in courses:
        root_modules = (
            db.query(Module)
            .filter(Module.course_id == course.id, Module.parent_id == None)
            .order_by(Module.order)
            .all()
        )
        tree.append(
            CourseTree(
                id=course.id,
                title=course.title,
                description=course.description,
                category_id=course.category_id,
                file_path=course.file_path,
                total_lessons=course.total_lessons,
                total_duration=course.total_duration,
                created_at=course.created_at,
                modules=[build_module_node(m) for m in root_modules],
            )
        )

    return tree
