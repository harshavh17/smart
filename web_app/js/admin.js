// ============================================================
// ADMIN PORTAL MODULE (ENTERPRISE EDITION)
// ============================================================

import { 
  db, 
  collection, 
  doc, 
  setDoc, 
  addDoc, 
  getDocs, 
  query, 
  orderBy, 
  onSnapshot, 
  serverTimestamp,
  deleteDoc,
  updateDoc
} from "./firebase-config.js";
import { showToast, currentUser, playSoundFeedback } from "./auth.js";
import { CLASSROOM_CONFIG } from "./student.js";

let adminAttendanceUnsubscribe = null;
let adminStudentsUnsubscribe = null;
let adminSchedulesUnsubscribe = null;
let adminMap = null;
let analyticsLineChart = null;
let departmentDoughnutChart = null;

let allAttendanceRecords = [];
let allStudentsList = [];
let studentRegPhoto = null;
let regCamStream = null;

// Initialize Admin Dashboard
export function initAdminDashboard() {
  listenToAdminAttendance();
  listenToAdminStudents();
  listenToAdminSchedules();
  initAnalyticsCharts();
}

// 1. Realtime Attendance Records
export function listenToAdminAttendance() {
  if (adminAttendanceUnsubscribe) adminAttendanceUnsubscribe();

  const tbody = document.getElementById("adminAttendanceTableBody");
  const todayCountEl = document.getElementById("adminTodayAttendanceCount");
  const totalCountEl = document.getElementById("adminTotalRecordsCount");
  const rateCountEl = document.getElementById("adminAttendanceRateMetric");

  const q = query(collection(db, "attendance"));

  adminAttendanceUnsubscribe = onSnapshot(q, (snapshot) => {
    allAttendanceRecords = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));

    // Sort descending by date
    allAttendanceRecords.sort((a, b) => {
      const timeA = a.date?.toMillis ? a.date.toMillis() : 0;
      const timeB = b.date?.toMillis ? b.date.toMillis() : 0;
      return timeB - timeA;
    });

    // Compute Today's Count
    const today = new Date().toDateString();
    let todayCount = 0;

    allAttendanceRecords.forEach(rec => {
      if (rec.date && rec.date.toDate) {
        if (rec.date.toDate().toDateString() === today && rec.status === "Present") {
          todayCount++;
        }
      }
    });

    if (todayCountEl) todayCountEl.textContent = todayCount.toString();
    if (totalCountEl) totalCountEl.textContent = allAttendanceRecords.length.toString();
    
    // Compute attendance rate percentage
    if (rateCountEl) {
      const totalStudents = allStudentsList.length || 1;
      const pct = Math.min(100, Math.round((todayCount / totalStudents) * 100));
      rateCountEl.textContent = `${pct}%`;
    }

    renderAdminAttendanceTable(allAttendanceRecords);
    updateAdminMapPins(allAttendanceRecords);
    updateLineChartData(allAttendanceRecords);
  });
}

// Render Attendance Table
export function renderAdminAttendanceTable(records) {
  const tbody = document.getElementById("adminAttendanceTableBody");
  if (!tbody) return;

  if (records.length === 0) {
    tbody.innerHTML = `<tr><td colspan="6" style="text-align: center; color: var(--text-dim); padding: 2.5rem;">No attendance records found.</td></tr>`;
    return;
  }

  let html = "";
  records.forEach(rec => {
    let dateFormatted = "N/A";
    if (rec.date && rec.date.toDate) {
      const d = rec.date.toDate();
      dateFormatted = `${d.toLocaleDateString()} ${d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;
    }

    const isPresent = rec.status === "Present";
    const statusBadgeClass = isPresent ? "status-present" : "status-failed";
    const statusIcon = isPresent ? "fa-circle-check" : "fa-circle-xmark";

    const lat = rec.latitude ? rec.latitude.toFixed(4) : "—";
    const lng = rec.longitude ? rec.longitude.toFixed(4) : "—";

    html += `
      <tr>
        <td>
          <div style="display: flex; align-items: center; gap: 10px;">
            <div class="user-avatar-small" style="background: ${isPresent ? 'rgba(37, 99, 235, 0.2)' : 'rgba(239, 68, 68, 0.2)'}; color: ${isPresent ? '#60A5FA' : '#F87171'};">
              <i class="fas ${isPresent ? 'fa-user-check' : 'fa-user-xmark'}"></i>
            </div>
            <strong>${rec.email || "Student"}</strong>
          </div>
        </td>
        <td>${dateFormatted}</td>
        <td>
          <span class="status-badge ${statusBadgeClass}">
            <i class="fas ${statusIcon}"></i> ${rec.status || "Present"}
          </span>
        </td>
        <td><i class="fas fa-map-marker-alt" style="color: ${isPresent ? '#34D399' : '#FB7185'};"></i> ${lat}, ${lng} ${rec.distanceFromClass ? `(${rec.distanceFromClass}m)` : ''}</td>
        <td>
          <span class="status-badge" style="background: rgba(96, 165, 250, 0.15); color: #60A5FA;">
            <i class="fas fa-face-smile"></i> ${rec.faceMatch ? `Match ${rec.faceMatch}%` : 'Biometrics'}
          </span>
        </td>
        <td>
          <button class="btn btn-outline btn-sm btn-danger" onclick="window.deleteAttendanceDoc('${rec.id}')" title="Delete record">
            <i class="fas fa-trash-can"></i>
          </button>
        </td>
      </tr>
    `;
  });

  tbody.innerHTML = html;
}

// Global Delete Attendance Record
window.deleteAttendanceDoc = async function(id) {
  if (!confirm("Are you sure you want to delete this attendance record?")) return;

  try {
    await deleteDoc(doc(db, "attendance", id));
    showToast("Attendance record removed.", "info");
  } catch (e) {
    showToast("Failed to delete record: " + e.message, "error");
  }
};

// Filter Attendance Table
export function filterAttendanceRecords() {
  const searchInput = document.getElementById("attendanceSearchInput");
  if (!searchInput) return;

  const queryText = searchInput.value.toLowerCase().trim();
  const filtered = allAttendanceRecords.filter(rec => {
    const email = (rec.email || "").toLowerCase();
    const status = (rec.status || "").toLowerCase();
    return email.includes(queryText) || status.includes(queryText);
  });

  renderAdminAttendanceTable(filtered);
}

// 2. Realtime Students Directory (With Delete Old User ID & Add New)
export function listenToAdminStudents() {
  if (adminStudentsUnsubscribe) adminStudentsUnsubscribe();

  const totalStudentsEl = document.getElementById("adminTotalStudentsCount");
  const studentTbody = document.getElementById("adminStudentsTableBody");

  const q = query(collection(db, "students"));

  adminStudentsUnsubscribe = onSnapshot(q, (snapshot) => {
    allStudentsList = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));

    if (totalStudentsEl) totalStudentsEl.textContent = allStudentsList.length.toString();

    updateDepartmentChart(allStudentsList);

    if (studentTbody) {
      if (allStudentsList.length === 0) {
        studentTbody.innerHTML = `<tr><td colspan="7" style="text-align: center; color: var(--text-dim); padding: 2.5rem;">No registered students found. Click "Add New Student" to create one.</td></tr>`;
        return;
      }

      let html = "";
      allStudentsList.forEach(st => {
        const hasPhoto = !!st.photoDataUrl;

        html += `
          <tr>
            <td>
              <div style="display: flex; align-items: center; gap: 12px;">
                <div class="user-avatar-small">
                  ${hasPhoto ? `<img src="${st.photoDataUrl}" alt="Face" />` : `<i class="fas fa-user-graduate"></i>`}
                </div>
                <div>
                  <div style="font-weight: 700;">${st.studentName || "N/A"}</div>
                  <div style="font-size: 0.8rem; color: var(--text-dim);">${st.email || ""}</div>
                </div>
              </div>
            </td>
            <td><span class="brand-badge" style="font-size: 0.8rem;">${st.usn || st.id}</span></td>
            <td>${st.department || "General"}</td>
            <td>Sem ${st.semester || "1"} (${st.section || "A"})</td>
            <td>${st.collegeName || "Main Campus"}</td>
            <td>
              <span class="status-badge status-present">
                <i class="fas fa-shield-check"></i> ${hasPhoto ? 'Face Enrolled' : 'Active'}
              </span>
            </td>
            <td>
              <div style="display: flex; gap: 8px;">
                <button class="btn btn-outline btn-sm btn-danger" onclick="window.deleteStudentProfile('${st.id}')" title="Delete old User ID">
                  <i class="fas fa-trash-can"></i> Remove ID
                </button>
              </div>
            </td>
          </tr>
        `;
      });
      studentTbody.innerHTML = html;
    }
  });
}

// Global Delete Student Profile (Remove Old User ID)
window.deleteStudentProfile = async function(usnKey) {
  if (!confirm(`Are you sure you want to delete student profile [${usnKey}]? This removes the old user ID from the database.`)) return;

  try {
    await deleteDoc(doc(db, "students", usnKey));
    showToast(`Student profile [${usnKey}] removed successfully!`, "info");
    playSoundFeedback("error");
  } catch (e) {
    showToast("Failed to delete student: " + e.message, "error");
  }
};

// 3. Realtime Class Schedules
export function listenToAdminSchedules() {
  if (adminSchedulesUnsubscribe) adminSchedulesUnsubscribe();

  const gridContainer = document.getElementById("adminSchedulesGrid");
  const scheduleCountEl = document.getElementById("adminActiveSchedulesCount");

  const q = query(collection(db, "class_schedules"));

  adminSchedulesUnsubscribe = onSnapshot(q, (snapshot) => {
    const schedules = snapshot.docs.map(d => ({ id: d.id, ...d.data() }));

    if (scheduleCountEl) scheduleCountEl.textContent = schedules.length.toString();

    if (!gridContainer) return;

    if (schedules.length === 0) {
      gridContainer.innerHTML = `
        <div style="grid-column: 1 / -1; text-align: center; padding: 3rem 1rem; color: var(--text-muted);">
          <i class="fas fa-calendar-xmark" style="font-size: 3rem; margin-bottom: 1rem; color: var(--text-dim);"></i>
          <h3>No Class Schedules Active</h3>
          <p>Add schedules below to automate class-time attendance constraints.</p>
        </div>
      `;
      return;
    }

    let html = "";
    schedules.forEach(s => {
      html += `
        <div class="schedule-card">
          <div style="display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 0.75rem;">
            <h4 style="font-size: 1.15rem; color: #F8FAFC;">${s.subject || "Course"}</h4>
            <span class="brand-badge" style="background: rgba(245, 158, 11, 0.2); color: #FBBF24; border-color: rgba(245, 158, 11, 0.4);">
              ${s.day || "All Days"}
            </span>
          </div>
          <div style="font-size: 0.9rem; color: var(--text-secondary); margin-bottom: 0.5rem;">
            <i class="fas fa-clock" style="color: #60A5FA; width: 18px;"></i> ${s.startTime || "09:00 AM"} - ${s.endTime || "10:00 AM"}
          </div>
          <div style="font-size: 0.9rem; color: var(--text-secondary); margin-bottom: 0.5rem;">
            <i class="fas fa-user-tie" style="color: #C084FC; width: 18px;"></i> ${s.faculty || "Faculty Instructor"}
          </div>
          <div style="font-size: 0.9rem; color: var(--text-muted); margin-bottom: 1rem;">
            <i class="fas fa-door-open" style="color: #34D399; width: 18px;"></i> Room: ${s.room || "101"} • Sem ${s.semester || "1"} (${s.section || "A"})
          </div>
          <button class="btn btn-outline btn-sm btn-danger" style="width: 100%;" onclick="window.deleteClassSchedule('${s.id}')">
            <i class="fas fa-trash-can"></i> Delete Schedule
          </button>
        </div>
      `;
    });

    gridContainer.innerHTML = html;
  });
}

// Add Class Schedule
export async function saveClassSchedule(scheduleData) {
  if (!scheduleData.subject || !scheduleData.faculty || !scheduleData.startTime || !scheduleData.endTime) {
    showToast("Please fill in all required schedule fields.", "error");
    return false;
  }

  try {
    await addDoc(collection(db, "class_schedules"), {
      ...scheduleData,
      createdAt: serverTimestamp()
    });
    showToast("Class schedule saved successfully!", "success");
    return true;
  } catch (error) {
    showToast("Error saving schedule: " + error.message, "error");
    return false;
  }
}

// Delete Class Schedule
window.deleteClassSchedule = async function(id) {
  if (!confirm("Are you sure you want to delete this class schedule?")) return;

  try {
    await deleteDoc(doc(db, "class_schedules", id));
    showToast("Schedule deleted successfully.", "info");
  } catch (e) {
    showToast("Failed to delete schedule: " + e.message, "error");
  }
};

// ============================================================
// ADD NEW STUDENT REGISTRATION MODAL
// ============================================================

export async function openAddStudentModal() {
  const modal = document.getElementById("addStudentModal");
  if (modal) modal.classList.add("active");
  studentRegPhoto = null;
}

export function closeAddStudentModal() {
  const modal = document.getElementById("addStudentModal");
  if (modal) modal.classList.remove("active");
  if (regCamStream) {
    regCamStream.getTracks().forEach(t => t.stop());
    regCamStream = null;
  }
}

export async function startStudentCamera() {
  const video = document.getElementById("regStudentVideo");
  const snapBtn = document.getElementById("regSnapBtn");
  const startBtn = document.getElementById("regStartCamBtn");

  try {
    regCamStream = await navigator.mediaDevices.getUserMedia({
      video: { width: 400, height: 400, facingMode: "user" }
    });
    if (video) {
      video.srcObject = regCamStream;
      video.style.display = "block";
      video.play();
    }
    if (startBtn) startBtn.style.display = "none";
    if (snapBtn) snapBtn.style.display = "inline-flex";
  } catch (err) {
    showToast("Could not access camera: " + err.message, "error");
  }
}

export function captureStudentRegPhoto() {
  const video = document.getElementById("regStudentVideo");
  const canvas = document.getElementById("regStudentCanvas");
  const preview = document.getElementById("regStudentPreview");
  const snapBtn = document.getElementById("regSnapBtn");

  if (!video || !canvas) return;

  const vW = video.videoWidth || 400;
  const vH = video.videoHeight || 400;
  const cropSize = Math.min(vW, vH);
  const startX = (vW - cropSize) / 2;
  const startY = (vH - cropSize) / 2;

  canvas.width = 400;
  canvas.height = 400;
  const ctx = canvas.getContext("2d");
  ctx.drawImage(video, startX, startY, cropSize, cropSize, 0, 0, 400, 400);

  studentRegPhoto = canvas.toDataURL("image/jpeg", 0.90);

  if (preview) {
    preview.src = studentRegPhoto;
    preview.style.display = "block";
  }
  if (video) video.style.display = "none";
  if (snapBtn) snapBtn.style.display = "none";

  if (regCamStream) {
    regCamStream.getTracks().forEach(t => t.stop());
    regCamStream = null;
  }

  showToast("Student facial biometrics captured.", "success");
}

export async function saveNewStudent(studentData) {
  if (!studentData.name || !studentData.usn || !studentData.email || !studentData.department) {
    showToast("Please fill all required student details.", "error");
    return false;
  }

  const usnKey = studentData.usn.toUpperCase().trim();

  try {
    await setDoc(doc(db, "students", usnKey), {
      studentName: studentData.name,
      usn: usnKey,
      email: studentData.email.trim(),
      department: studentData.department,
      semester: studentData.semester || "1",
      section: studentData.section || "A",
      collegeName: studentData.college || "Smart Attendance University",
      photoDataUrl: studentRegPhoto || "",
      createdAt: serverTimestamp()
    });

    showToast(`New student ${studentData.name} (${usnKey}) registered!`, "success");
    closeAddStudentModal();
    return true;
  } catch (error) {
    showToast("Failed to register student: " + error.message, "error");
    return false;
  }
}

// ============================================================
// ADMIN LIVE LOCATION MAP & GEOFENCE CALIBRATION
// ============================================================

export function initAdminLocationMap() {
  const mapContainer = document.getElementById("adminLeafletMap");
  if (!mapContainer || typeof L === "undefined") return;

  if (!adminMap) {
    adminMap = L.map("adminLeafletMap").setView([CLASSROOM_CONFIG.lat, CLASSROOM_CONFIG.lng], 15);

    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap contributors"
    }).addTo(adminMap);

    // Classroom Boundary
    L.circle([CLASSROOM_CONFIG.lat, CLASSROOM_CONFIG.lng], {
      color: "#2563EB",
      fillColor: "#3B82F6",
      fillOpacity: 0.2,
      radius: CLASSROOM_CONFIG.radiusMeters
    }).addTo(adminMap).bindPopup("<b>Smart Attendance Classroom Geofence Zone</b>");
  }

  updateAdminMapPins(allAttendanceRecords);
}

function updateAdminMapPins(records) {
  if (!adminMap || typeof L === "undefined") return;

  records.slice(0, 30).forEach(rec => {
    if (rec.latitude && rec.longitude) {
      let timeText = "Today";
      if (rec.date && rec.date.toDate) {
        timeText = rec.date.toDate().toLocaleTimeString();
      }

      const isPresent = rec.status === "Present";

      L.marker([rec.latitude, rec.longitude])
        .addTo(adminMap)
        .bindPopup(`
          <div style="font-family: inherit; min-width: 150px;">
            <b style="color: #2563EB;">${rec.email}</b><br/>
            <span>Status: <b style="color: ${isPresent ? '#10B981' : '#EF4444'};">${rec.status}</b></span><br/>
            <small style="color: #64748B;">Time: ${timeText}</small>
          </div>
        `);
    }
  });
}

// Calibrate Classroom Geofence to Current GPS
export function calibrateClassroomLocation() {
  if (!navigator.geolocation) {
    showToast("Geolocation not supported.", "error");
    return;
  }

  navigator.geolocation.getCurrentPosition((pos) => {
    CLASSROOM_CONFIG.lat = pos.coords.latitude;
    CLASSROOM_CONFIG.lng = pos.coords.longitude;
    showToast(`Classroom Radar calibrated to current GPS: [${pos.coords.latitude.toFixed(5)}, ${pos.coords.longitude.toFixed(5)}]`, "success");
    if (adminMap) {
      adminMap.setView([CLASSROOM_CONFIG.lat, CLASSROOM_CONFIG.lng], 16);
    }
  }, (err) => {
    showToast("Could not get current location: " + err.message, "error");
  }, { enableHighAccuracy: true });
}

// ============================================================
// ATTENDANCE ANALYTICS CHARTS (CHART.JS)
// ============================================================

export function initAnalyticsCharts() {
  // Line Chart
  const lineCtx = document.getElementById("attendanceChart");
  if (lineCtx && typeof Chart !== "undefined") {
    if (analyticsLineChart) analyticsLineChart.destroy();

    analyticsLineChart = new Chart(lineCtx, {
      type: "line",
      data: {
        labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat"],
        datasets: [
          {
            label: "Attendance Rate (%)",
            data: [94, 98, 92, 96, 95, 99],
            borderColor: "#3B82F6",
            backgroundColor: "rgba(59, 130, 246, 0.15)",
            borderWidth: 3,
            fill: true,
            tension: 0.35,
            pointBackgroundColor: "#60A5FA",
            pointRadius: 4
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { labels: { color: "#CBD5E1" } }
        },
        scales: {
          x: { ticks: { color: "#94A3B8" }, grid: { color: "rgba(255,255,255,0.05)" } },
          y: { ticks: { color: "#94A3B8" }, grid: { color: "rgba(255,255,255,0.05)" }, min: 50, max: 100 }
        }
      }
    });
  }

  // Department Doughnut Chart
  const doughnutCtx = document.getElementById("departmentChart");
  if (doughnutCtx && typeof Chart !== "undefined") {
    if (departmentDoughnutChart) departmentDoughnutChart.destroy();

    departmentDoughnutChart = new Chart(doughnutCtx, {
      type: "doughnut",
      data: {
        labels: ["CSE", "ISE", "ECE", "AIML", "Mech"],
        datasets: [
          {
            data: [45, 25, 15, 10, 5],
            backgroundColor: ["#3B82F6", "#8B5CF6", "#10B981", "#F59E0B", "#F43F5E"],
            borderWidth: 0
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { position: "right", labels: { color: "#CBD5E1" } }
        }
      }
    });
  }
}

function updateLineChartData(records) {
  if (!analyticsLineChart) return;
}

function updateDepartmentChart(students) {
  if (!departmentDoughnutChart) return;

  const counts = {};
  students.forEach(st => {
    const dept = (st.department || "General").toUpperCase();
    counts[dept] = (counts[dept] || 0) + 1;
  });

  const labels = Object.keys(counts);
  const data = Object.values(counts);

  if (labels.length > 0) {
    departmentDoughnutChart.data.labels = labels;
    departmentDoughnutChart.data.datasets[0].data = data;
    departmentDoughnutChart.update();
  }
}

// ============================================================
// EXPORT & PRINT REPORTS
// ============================================================

export function exportAttendanceCSV() {
  if (allAttendanceRecords.length === 0) {
    showToast("No attendance records to export.", "warning");
    return;
  }

  const headers = ["Student Email", "Date", "Time", "Status", "Latitude", "Longitude", "Verified Method"];
  const rows = allAttendanceRecords.map(rec => {
    let dStr = "N/A";
    let tStr = "N/A";
    if (rec.date && rec.date.toDate) {
      const d = rec.date.toDate();
      dStr = d.toLocaleDateString();
      tStr = d.toLocaleTimeString();
    }
    return [
      `"${rec.email || ''}"`,
      `"${dStr}"`,
      `"${tStr}"`,
      `"${rec.status || 'Present'}"`,
      rec.latitude || '',
      rec.longitude || '',
      `"${rec.verifiedMethod || 'Smart Attendance Biometrics + GPS'}"`
    ];
  });

  const csvContent = "data:text/csv;charset=utf-8," + [headers.join(","), ...rows.map(e => e.join(","))].join("\n");
  const encodedUri = encodeURI(csvContent);
  const link = document.createElement("a");
  link.setAttribute("href", encodedUri);
  link.setAttribute("download", `smart_attendance_report_${new Date().toISOString().slice(0,10)}.csv`);
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);

  showToast("Attendance CSV report exported successfully!", "success");
}

export function printAttendanceReport() {
  window.print();
}
