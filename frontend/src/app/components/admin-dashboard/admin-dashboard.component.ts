import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../header/header.component';
import { CourseService } from '../../services/course.service';
import { Category, CourseTree, ScanResult, User } from '../../models/models';
import { AuthService } from '../../services/auth.service';
import { ModuleBranchComponent } from './module-branch.component';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule, HeaderComponent, ModuleBranchComponent],
  templateUrl: './admin-dashboard.component.html',
  styleUrls: ['./admin-dashboard.component.scss']
})
export class AdminDashboardComponent implements OnInit {
  courseTree: CourseTree[] = [];
  categories: Category[] = [];
  scanResult: ScanResult | null = null;
  loading = false;
  currentUser: User | null = null;

  constructor(
    private courseService: CourseService,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    this.authService.currentUser$.subscribe(user => this.currentUser = user);
    this.loadCategories();
    this.loadTree();
  }

  loadCategories(): void {
    this.courseService.getCategories().subscribe({
      next: (cats) => this.categories = [{ id: 0, name: 'None', icon: '', description: '' }, ...cats],
      error: (err) => console.error('Error loading categories', err)
    });
  }

  loadTree(): void {
    this.courseService.getCourseTree().subscribe({
      next: (tree) => this.courseTree = tree,
      error: (err) => console.error('Error loading course tree', err)
    });
  }

  rescan(): void {
    if (this.currentUser && !this.currentUser.is_admin) {
      return;
    }
    this.loading = true;
    this.courseService.rescanCourses().subscribe({
      next: (result) => {
        this.scanResult = result;
        this.loading = false;
        this.loadTree();
      },
      error: (err) => {
        console.error('Scan failed', err);
        this.loading = false;
      }
    });
  }

  updateCourseCategory(courseId: number, categoryId: number | null): void {
    const payloadId = categoryId && categoryId > 0 ? categoryId : null;
    this.courseService.updateCourseCategory(courseId, payloadId).subscribe({
      next: () => this.loadTree(),
      error: (err) => console.error('Failed to update course category', err)
    });
  }
}

