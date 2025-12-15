import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CourseTree, ModuleNode, LessonNode } from '../../models/models';
import { ModuleTreeNodeComponent } from './module-tree-node.component';

@Component({
  selector: 'app-course-treeview',
  standalone: true,
  imports: [CommonModule, ModuleTreeNodeComponent],
  templateUrl: './course-treeview.component.html',
  styleUrls: ['./course-treeview.component.scss']
})
export class CourseTreeviewComponent {
  @Input() courses: CourseTree[] = [];
  @Input() selectedLesson: LessonNode | null = null;
  @Output() lessonSelected = new EventEmitter<LessonNode>();
  
  expandedCourses: Set<number> = new Set();
  expandedModules: Set<number> = new Set();

  toggleCourse(courseId: number): void {
    if (this.expandedCourses.has(courseId)) {
      this.expandedCourses.delete(courseId);
    } else {
      this.expandedCourses.add(courseId);
    }
  }

  toggleModule(moduleId: number): void {
    if (this.expandedModules.has(moduleId)) {
      this.expandedModules.delete(moduleId);
    } else {
      this.expandedModules.add(moduleId);
    }
  }

  isCourseExpanded(courseId: number): boolean {
    return this.expandedCourses.has(courseId);
  }

  isModuleExpanded(moduleId: number): boolean {
    return this.expandedModules.has(moduleId);
  }

  selectLesson(lesson: LessonNode): void {
    this.lessonSelected.emit(lesson);
  }

  expandModuleRecursive(modules: ModuleNode[]): void {
    modules.forEach(module => {
      this.expandedModules.add(module.id);
      if (module.children && module.children.length > 0) {
        this.expandModuleRecursive(module.children);
      }
    });
  }

  expandCourse(course: CourseTree): void {
    this.expandedCourses.add(course.id);
    if (course.modules && course.modules.length > 0) {
      this.expandModuleRecursive(course.modules);
    }
  }
}

