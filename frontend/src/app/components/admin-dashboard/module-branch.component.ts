import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ModuleNode } from '../../models/models';

@Component({
  selector: 'app-module-branch',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div *ngFor="let child of module.children">
      <div class="module-node" [style.paddingLeft.px]="depth * 16">
        <div class="title">{{ child.title }}</div>
        <div class="meta">{{ child.file_path }}</div>
      </div>

      <div class="lesson-node"
           *ngFor="let lesson of child.lessons"
           [style.paddingLeft.px]="(depth + 1) * 16">
        {{ lesson.title }} ({{ lesson.file_type }})
        <small class="meta">{{ lesson.file_path }}</small>
      </div>

      <app-module-branch *ngIf="child.children.length"
                         [module]="child"
                         [depth]="depth + 1"></app-module-branch>
    </div>
  `,
  styles: [`
    .module-node { margin-top: 8px; font-weight: 600; }
    .lesson-node { margin-top: 4px; font-size: 13px; }
    .meta { color: #6b7280; font-size: 12px; }
  `]
})
export class ModuleBranchComponent {
  @Input() module!: ModuleNode;
  @Input() depth = 1;
}

