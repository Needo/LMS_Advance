import { Routes } from '@angular/router';
import { LoginComponent } from './components/login/login.component';
import { CourseBrowserComponent } from './components/course-browser/course-browser.component';
import { authGuard } from './guards/auth.guard';

export const routes: Routes = [
  { path: '', redirectTo: '/login', pathMatch: 'full' },
  { path: 'login', component: LoginComponent },
  { 
    path: 'courses', 
    component: CourseBrowserComponent,
    canActivate: [authGuard]
  },
  { path: '**', redirectTo: '/login' }
];
