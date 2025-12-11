import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { HeaderComponent } from '../header/header.component';
import { SidebarComponent } from '../sidebar/sidebar.component';
import { CourseService } from '../../services/course.service';
import { Course, Category } from '../../models/models';

@Component({
  selector: 'app-course-browser',
  standalone: true,
  imports: [CommonModule, HeaderComponent, SidebarComponent],
  templateUrl: './course-browser.component.html',
  styleUrls: ['./course-browser.component.scss']
})
export class CourseBrowserComponent implements OnInit {
  courses: Course[] = [];
  categories: Category[] = [];
  selectedCategory: number | null = null;
  loading = true;

  constructor(private courseService: CourseService) {}

  ngOnInit(): void {
    this.loadCategories();
    this.loadCourses();
  }

  loadCategories(): void {
    this.courseService.getCategories().subscribe({
      next: (categories) => {
        this.categories = categories;
      },
      error: (err) => console.error('Error loading categories:', err)
    });
  }

  loadCourses(): void {
    this.loading = true;
    if (this.selectedCategory) {
      this.courseService.getCoursesByCategory(this.selectedCategory).subscribe({
        next: (courses) => {
          this.courses = courses;
          this.loading = false;
        },
        error: (err) => {
          console.error('Error loading courses:', err);
          this.loading = false;
        }
      });
    } else {
      this.courseService.getAllCourses().subscribe({
        next: (courses) => {
          this.courses = courses;
          this.loading = false;
        },
        error: (err) => {
          console.error('Error loading courses:', err);
          this.loading = false;
        }
      });
    }
  }

  filterByCategory(categoryId: number | null): void {
    this.selectedCategory = categoryId;
    this.loadCourses();
  }

  openCourse(courseId: number): void {
    alert(`Opening course ${courseId} - Course viewer coming soon!`);
  }

  formatDuration(seconds: number): string {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    return hours > 0 ? `${hours}h ${minutes}m` : `${minutes}m`;
  }
}
