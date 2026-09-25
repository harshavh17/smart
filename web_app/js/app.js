// ============================================================
// MAIN APP CONTROLLER & EVENT WIRING (ENTERPRISE EDITION)
// ============================================================

import {
  initAuthListener,
  loginStudent,
  loginAdmin,
  registerStudentAccount,
  handleSignOut,
  switchView,
  showToast,
  currentUser,
  userRole
} from "./auth.js";

import {
  initStudentDashboard,
  openScannerModal,
  closeScannerModal,
  captureSnapshot,
  retrySnapshot,
  submitAttendance,
  openLocationModal,
  closeLocationModal,
  openEnrollFaceModal,
  closeEnrollFaceModal,
  startEnrollCamera,
  captureEnrollPhoto,
  submitEnrollFace
} from "./student.js";

import {
  initAdminDashboard,
  openAddStudentModal,
  closeAddStudentModal,
  startStudentCamera,
  captureStudentRegPhoto,
  saveNewStudent,
  saveClassSchedule,
  filterAttendanceRecords,
  exportAttendanceCSV,
  printAttendanceReport,
  initAdminLocationMap,
  calibrateClassroomLocation
} from "./admin.js";

// DOM Ready
document.addEventListener("DOMContentLoaded", () => {
  // 1. Initialize Auth state
  initAuthListener((user, role) => {
    if (user) {
      if (role === "admin") {
        switchView("adminDashboardView");
        initAdminDashboard();
      } else {
        switchView("studentDashboardView");
        initStudentDashboard();
      }
    } else {
      switchView("roleSelectionView");
    }
  });

  // 2. Role Selector Navigation
  document.getElementById("selectStudentRoleCard")?.addEventListener("click", () => {
    switchView("studentLoginView");
  });

  document.getElementById("selectAdminRoleCard")?.addEventListener("click", () => {
    switchView("adminLoginView");
  });

  document.getElementById("backToRoleFromStudent")?.addEventListener("click", () => {
    switchView("roleSelectionView");
  });

  document.getElementById("backToRoleFromAdmin")?.addEventListener("click", () => {
    switchView("roleSelectionView");
  });

  document.getElementById("navBrandHome")?.addEventListener("click", () => {
    if (currentUser) {
      if (userRole === "admin") switchView("adminDashboardView");
      else switchView("studentDashboardView");
    } else {
      switchView("roleSelectionView");
    }
  });

  // 3. Student Auth Tabs (Sign In vs Sign Up / Create New User)
  const tabSignInBtn = document.getElementById("tabSignInBtn");
  const tabSignUpBtn = document.getElementById("tabSignUpBtn");
  const studentSignInForm = document.getElementById("studentLoginForm");
  const studentSignUpForm = document.getElementById("studentSignUpForm");

  tabSignInBtn?.addEventListener("click", () => {
    tabSignInBtn.classList.add("active");
    tabSignUpBtn.classList.remove("active");
    if (studentSignInForm) studentSignInForm.style.display = "block";
    if (studentSignUpForm) studentSignUpForm.style.display = "none";
  });

  tabSignUpBtn?.addEventListener("click", () => {
    tabSignUpBtn.classList.add("active");
    tabSignInBtn.classList.remove("active");
    if (studentSignInForm) studentSignInForm.style.display = "none";
    if (studentSignUpForm) studentSignUpForm.style.display = "block";
  });

  // 4. Student Sign In Form Submit
  studentSignInForm?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const email = document.getElementById("studentEmailInput").value.trim();
    const password = document.getElementById("studentPasswordInput").value;
    const btn = document.getElementById("studentLoginBtn");

    if (btn) {
      btn.disabled = true;
      btn.innerHTML = `<i class="fas fa-spinner fa-spin"></i> Authenticating...`;
    }

    const success = await loginStudent(email, password);
    if (success) {
      initStudentDashboard();
    }

    if (btn) {
      btn.disabled = false;
      btn.innerHTML = `<i class="fas fa-right-to-bracket"></i> SIGN IN`;
    }
  });

  // 5. Student Self Sign-Up Form Submit (Make New User ID)
  studentSignUpForm?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const data = {
      name: document.getElementById("newStudentName").value.trim(),
      usn: document.getElementById("newStudentUsn").value.trim(),
      email: document.getElementById("newStudentEmail").value.trim(),
      password: document.getElementById("newStudentPassword").value,
      department: document.getElementById("newStudentDept").value.trim(),
      semester: document.getElementById("newStudentSemester").value.trim(),
      section: document.getElementById("newStudentSection").value.trim(),
      college: document.getElementById("newStudentCollege").value.trim()
    };

    const btn = document.getElementById("studentSignUpBtn");
    if (btn) {
      btn.disabled = true;
      btn.innerHTML = `<i class="fas fa-spinner fa-spin"></i> Creating Account...`;
    }

    const success = await registerStudentAccount(data);
    if (success) {
      initStudentDashboard();
      studentSignUpForm.reset();
    }

    if (btn) {
      btn.disabled = false;
      btn.innerHTML = `<i class="fas fa-user-plus"></i> CREATE ACCOUNT`;
    }
  });

  // 6. Admin Login Form Submit
  document.getElementById("adminLoginForm")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const email = document.getElementById("adminEmailInput").value.trim();
    const password = document.getElementById("adminPasswordInput").value;
    const btn = document.getElementById("adminLoginBtn");

    if (btn) {
      btn.disabled = true;
      btn.innerHTML = `<i class="fas fa-spinner fa-spin"></i> Authenticating...`;
    }

    const success = await loginAdmin(email, password);
    if (success) {
      initAdminDashboard();
    }

    if (btn) {
      btn.disabled = false;
      btn.innerHTML = `<i class="fas fa-shield-halved"></i> ADMIN SIGN IN`;
    }
  });

  // 7. Demo Quick-Fill Buttons
  document.getElementById("demoAdminPill")?.addEventListener("click", () => {
    const emailIn = document.getElementById("adminEmailInput");
    const passIn = document.getElementById("adminPasswordInput");
    if (emailIn) emailIn.value = "admin@gmail.com";
    if (passIn) passIn.value = "admin123";
    showToast("Filled Admin demo credentials", "info");
  });

  document.getElementById("demoStudentPill")?.addEventListener("click", () => {
    const emailIn = document.getElementById("studentEmailInput");
    const passIn = document.getElementById("studentPasswordInput");
    if (emailIn) emailIn.value = "student@gmail.com";
    if (passIn) passIn.value = "student123";
    showToast("Filled Student demo credentials", "info");
  });

  // 8. Global Sign Out
  document.getElementById("navLogoutBtn")?.addEventListener("click", handleSignOut);
  document.getElementById("studentLogoutBtn")?.addEventListener("click", handleSignOut);
  document.getElementById("adminLogoutBtn")?.addEventListener("click", handleSignOut);

  // 9. Student Dashboard Actions
  document.getElementById("btnMarkAttendance")?.addEventListener("click", openScannerModal);
  document.getElementById("btnLiveLocation")?.addEventListener("click", openLocationModal);
  document.getElementById("btnAttendanceHistory")?.addEventListener("click", () => {
    document.getElementById("studentHistorySection")?.scrollIntoView({ behavior: "smooth" });
  });

  // 10. Scanner Modal Buttons
  document.getElementById("closeScannerModalBtn")?.addEventListener("click", closeScannerModal);
  document.getElementById("cancelScannerBtn")?.addEventListener("click", closeScannerModal);
  document.getElementById("snapPhotoBtn")?.addEventListener("click", captureSnapshot);
  document.getElementById("retryPhotoBtn")?.addEventListener("click", retrySnapshot);
  document.getElementById("confirmAttendanceBtn")?.addEventListener("click", submitAttendance);

  // 10b. Face ID Biometric Enrollment Modal Buttons
  document.getElementById("btnEnrollFaceID")?.addEventListener("click", openEnrollFaceModal);
  document.getElementById("closeEnrollFaceModalBtn")?.addEventListener("click", closeEnrollFaceModal);
  document.getElementById("cancelEnrollBtn")?.addEventListener("click", closeEnrollFaceModal);
  document.getElementById("startEnrollCamBtn")?.addEventListener("click", startEnrollCamera);
  document.getElementById("snapEnrollBtn")?.addEventListener("click", captureEnrollPhoto);
  document.getElementById("saveEnrollFaceBtn")?.addEventListener("click", submitEnrollFace);

  // 11. Location Modal Buttons
  document.getElementById("closeLocationModalBtn")?.addEventListener("click", closeLocationModal);
  document.getElementById("closeLocationBtnAction")?.addEventListener("click", closeLocationModal);

  // 12. Admin Navigation Tabs
  document.querySelectorAll(".admin-tab-btn").forEach(tab => {
    tab.addEventListener("click", (e) => {
      document.querySelectorAll(".admin-tab-btn").forEach(t => t.classList.remove("active"));
      document.querySelectorAll(".admin-tab-content").forEach(c => c.style.display = "none");

      const targetTab = e.currentTarget.getAttribute("data-tab");
      e.currentTarget.classList.add("active");

      const targetContent = document.getElementById(targetTab);
      if (targetContent) {
        targetContent.style.display = "block";
      }

      if (targetTab === "adminLiveLocationsTab") {
        setTimeout(initAdminLocationMap, 150);
      }
    });
  });

  // 13. Admin Search, CSV Export, Print & Calibration
  document.getElementById("attendanceSearchInput")?.addEventListener("input", filterAttendanceRecords);
  document.getElementById("exportCsvBtn")?.addEventListener("click", exportAttendanceCSV);
  document.getElementById("printReportBtn")?.addEventListener("click", printAttendanceReport);
  document.getElementById("btnCalibrateLocation")?.addEventListener("click", calibrateClassroomLocation);

  // 14. Add Student Modal & Registration (Admin Mode)
  document.getElementById("openAddStudentBtn")?.addEventListener("click", openAddStudentModal);
  document.getElementById("closeAddStudentModalBtn")?.addEventListener("click", closeAddStudentModal);
  document.getElementById("cancelAddStudentBtn")?.addEventListener("click", closeAddStudentModal);
  document.getElementById("regStartCamBtn")?.addEventListener("click", startStudentCamera);
  document.getElementById("regSnapBtn")?.addEventListener("click", captureStudentRegPhoto);

  document.getElementById("addStudentForm")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const studentData = {
      name: document.getElementById("regStudentName").value.trim(),
      usn: document.getElementById("regStudentUsn").value.trim(),
      email: document.getElementById("regStudentEmail").value.trim(),
      department: document.getElementById("regStudentDept").value.trim(),
      semester: document.getElementById("regStudentSemester").value.trim(),
      section: document.getElementById("regStudentSection").value.trim(),
      college: document.getElementById("regStudentCollege").value.trim()
    };

    const success = await saveNewStudent(studentData);
    if (success) {
      document.getElementById("addStudentForm").reset();
      const preview = document.getElementById("regStudentPreview");
      if (preview) preview.style.display = "none";
    }
  });

  // 15. Add Class Schedule Form
  document.getElementById("addClassScheduleForm")?.addEventListener("submit", async (e) => {
    e.preventDefault();
    const scheduleData = {
      subject: document.getElementById("schedSubject").value.trim(),
      semester: document.getElementById("schedSemester").value.trim(),
      section: document.getElementById("schedSection").value.trim(),
      faculty: document.getElementById("schedFaculty").value.trim(),
      room: document.getElementById("schedRoom").value.trim(),
      day: document.getElementById("schedDay").value,
      startTime: document.getElementById("schedStartTime").value,
      endTime: document.getElementById("schedEndTime").value
    };

    const success = await saveClassSchedule(scheduleData);
    if (success) {
      document.getElementById("addClassScheduleForm").reset();
    }
  });

  // Password toggles
  document.querySelectorAll(".form-input-toggle").forEach(toggle => {
    toggle.addEventListener("click", () => {
      const input = toggle.parentElement.querySelector("input");
      if (input.type === "password") {
        input.type = "text";
        toggle.classList.replace("fa-eye", "fa-eye-slash");
      } else {
        input.type = "password";
        toggle.classList.replace("fa-eye-slash", "fa-eye");
      }
    });
  });
});
