import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ModuleNode, LessonNode } from '../../models/models';

@Component({
  selector: 'app-module-tree-node',
  standalone: true,
  imports: [CommonModule],
  templateUrl: './module-tree-node.component.html',
  styleUrls: ['./module-tree-node.component.scss']
})
export class ModuleTreeNodeComponent {
  @Input() module!: ModuleNode;
  @Input() selectedLesson: LessonNode | null = null;
  @Input() expandedModules: Set<number> = new Set();
  @Output() lessonSelected = new EventEmitter<LessonNode>();
  @Output() moduleToggled = new EventEmitter<number>();

  toggleModule(): void {
    this.moduleToggled.emit(this.module.id);
  }

  isExpanded(): boolean {
    return this.expandedModules.has(this.module.id);
  }

  selectLesson(lesson: LessonNode): void {
    this.lessonSelected.emit(lesson);
  }

  hasChildren(): boolean {
    return (this.module.children && this.module.children.length > 0) || 
           (this.module.lessons && this.module.lessons.length > 0);
  }
}


