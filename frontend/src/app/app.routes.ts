import { Routes } from '@angular/router';
import { LoginComponent } from './components/login/login.component';
import { CourseBrowserComponent } from './components/course-browser/course-browser.component';
import { AdminDashboardComponent } from './components/admin-dashboard/admin-dashboard.component';
import { authGuard } from './guards/auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: '/login', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { 
    path: 'courses', 
    component: CourseBrowserComponent,
    canActivate: [authGuard]
  },
  { 
    path: 'admin',
    component: AdminDashboardComponent,
    canActivate: [authGuard]
  },
  { path: '**', redirectTo: '/login' }
];
