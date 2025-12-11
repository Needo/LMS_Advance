import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../header/header.component';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { CourseService } from '../../services/course.service';
import { CourseTree, ScanResult, User } from '../../models/models';
import { AuthService } from '../../services/auth.service';
import { ModuleBranchComponent } from './module-branch.component';

@Component({
  selector: 'app-admin-dashboard',
  standalone: true,
  imports: [CommonModule, HeaderComponent, SidebarComponent, ModuleBranchComponent],
  templateUrl: './admin-dashboard.component.html',
  styleUrls: ['./admin-dashboard.component.scss']
})
export class AdminDashboardComponent implements OnInit {
  courseTree: CourseTree[] = [];
  scanResult: ScanResult | null = null;
  loading = false;
  currentUser: User | null = null;

  constructor(
    private courseService: CourseService,
    private authService: AuthService
  ) {}

  ngOnInit(): void {
    this.authService.currentUser$.subscribe(user => this.currentUser = user);
    this.loadTree();
  }

  loadTree(): void {
    this.courseService.getCourseTree().subscribe({
      next: (tree) => this.courseTree = tree,
      error: (err) => console.error('Error loading course tree', err)
    });
  }

  onCategorySelected(_: number | null): void {
    // Admin view ignores category filtering for now
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
}

