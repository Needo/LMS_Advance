import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Course, Category, CourseTree, ScanResult } from '../models/models';

@Injectable({
  providedIn: 'root'
})
export class CourseService {
  private apiUrl = 'http://localhost:8000/api';

  constructor(private http: HttpClient) {}

  getCategories(): Observable<Category[]> {
    return this.http.get<Category[]>(`${this.apiUrl}/categories`);
  }

  getAllCourses(): Observable<Course[]> {
    return this.http.get<Course[]>(`${this.apiUrl}/courses`);
  }

  getCoursesByCategory(categoryId: number): Observable<Course[]> {
    return this.http.get<Course[]>(`${this.apiUrl}/courses/category/${categoryId}`);
  }

  getCourse(courseId: number): Observable<Course> {
    return this.http.get<Course>(`${this.apiUrl}/courses/${courseId}`);
  }

  updateCourseCategory(courseId: number, categoryId: number | null): Observable<Course> {
    return this.http.patch<Course>(`${this.apiUrl}/courses/${courseId}/category`, {
      category_id: categoryId
    });
  }

  getCourseTree(): Observable<CourseTree[]> {
    return this.http.get<CourseTree[]>(`${this.apiUrl}/courses/tree`);
  }

  rescanCourses(): Observable<ScanResult> {
    return this.http.post<ScanResult>(`${this.apiUrl}/scanner/scan`, {});
  }
}
