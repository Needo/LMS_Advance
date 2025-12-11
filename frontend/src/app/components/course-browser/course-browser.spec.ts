import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CourseBrowser } from './course-browser';

describe('CourseBrowser', () => {
  let component: CourseBrowser;
  let fixture: ComponentFixture<CourseBrowser>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CourseBrowser]
    })
    .compileComponents();

    fixture = TestBed.createComponent(CourseBrowser);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
