import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../header/header.component';
import { CourseTreeviewComponent } from '../course-treeview/course-treeview.component';
import { FileViewerComponent } from '../file-viewer/file-viewer.component';
import { CourseService } from '../../services/course.service';
import { CourseTree, LessonNode } from '../../models/models';

@Component({
  selector: 'app-course-browser',
  standalone: true,
  imports: [CommonModule, HeaderComponent, CourseTreeviewComponent, FileViewerComponent],
  templateUrl: './course-browser.component.html',
  styleUrls: ['./course-browser.component.scss']
})
export class CourseBrowserComponent implements OnInit {
  courses: CourseTree[] = [];
  selectedLesson: LessonNode | null = null;
  flatLessons: LessonNode[] = [];
  loading = true;
  playbackRate = 1;

  constructor(private courseService: CourseService) {}

  ngOnInit(): void {
    this.loadCourseTree();
  }

  loadCourseTree(): void {
    this.loading = true;
    this.courseService.getCourseTree().subscribe({
      next: (tree) => {
        this.courses = tree || [];
        this.loading = false;
        // Flatten all lessons for navigation
        this.flatLessons = this.flattenAllLessons(this.courses);
      },
      error: (err) => {
        console.error('Error loading courses:', err);
        this.loading = false;
      }
    });
  }

  flattenAllLessons(courses: CourseTree[]): LessonNode[] {
    const allLessons: LessonNode[] = [];
    const walkModules = (modules: any[]) => {
      modules.forEach(module => {
        if (module.lessons) {
          allLessons.push(...module.lessons);
        }
        if (module.children) {
          walkModules(module.children);
        }
      });
    };
    courses.forEach(course => {
      if (course.modules) {
        walkModules(course.modules);
      }
    });
    return allLessons;
  }

  onLessonSelected(lesson: LessonNode): void {
    this.selectedLesson = lesson;
  }

  goPrevLesson(): void {
    if (!this.selectedLesson) return;
    const idx = this.flatLessons.findIndex(l => l.id === this.selectedLesson?.id);
    if (idx > 0) {
      this.selectedLesson = this.flatLessons[idx - 1];
    }
  }

  goNextLesson(): void {
    if (!this.selectedLesson) return;
    const idx = this.flatLessons.findIndex(l => l.id === this.selectedLesson?.id);
    if (idx >= 0 && idx < this.flatLessons.length - 1) {
      this.selectedLesson = this.flatLessons[idx + 1];
    }
  }

  changePlaybackRate(rate: number): void {
    this.playbackRate = rate;
  }
}
