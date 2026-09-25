// ============================================================
// AUTHENTICATION & VIEW ROUTER MODULE (ENTERPRISE EDITION)
// ============================================================

import { 
  auth, 
  signInWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged,
  createUserWithEmailAndPassword,
  db,
  doc,
  setDoc,
  getDoc,
  getDocs,
  collection,
  query,
  where,
  updateDoc,
  serverTimestamp
} from "./firebase-config.js";

// Web Audio API Chime & Feedback Generator
export function playSoundFeedback(type = "success") {
  try {
    const AudioContext = window.AudioContext || window.webkitAudioContext;
    if (!AudioContext) return;
    const ctx = new AudioContext();

    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.connect(gain);
    gain.connect(ctx.destination);

    if (type === "success") {
      // Pleasant futuristic ascending chime
      osc.type = "sine";
      osc.frequency.setValueAtTime(587.33, ctx.currentTime); // D5
      osc.frequency.exponentialRampToValueAtTime(880.00, ctx.currentTime + 0.15); // A5
      gain.gain.setValueAtTime(0.15, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.25);
      osc.start(ctx.currentTime);
      osc.stop(ctx.currentTime + 0.25);
    } else if (type === "error") {
      // Warning low pulse
      osc.type = "sawtooth";
      osc.frequency.setValueAtTime(220, ctx.currentTime);
      osc.frequency.linearRampToValueAtTime(130, ctx.currentTime + 0.22);
      gain.gain.setValueAtTime(0.2, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.22);
      osc.start(ctx.currentTime);
      osc.stop(ctx.currentTime + 0.22);
    } else if (type === "scan") {
      // High-tech radar blip
      osc.type = "triangle";
      osc.frequency.setValueAtTime(1200, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(1600, ctx.currentTime + 0.08);
      gain.gain.setValueAtTime(0.1, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.01, ctx.currentTime + 0.08);
      osc.start(ctx.currentTime);
      osc.stop(ctx.currentTime + 0.08);
    }
  } catch (e) {
    // Audio context may be restricted by autoplay policy until user gesture
  }
}

// Global Toast Notification Helper
export function showToast(message, type = "info") {
  const container = document.getElementById("toast-container");
  if (!container) return;

  const toast = document.createElement("div");
  toast.className = `toast ${type}`;
  
  let icon = "fa-info-circle";
  if (type === "success") icon = "fa-check-circle";
  if (type === "error") icon = "fa-triangle-exclamation";
  if (type === "warning") icon = "fa-exclamation-circle";

  toast.innerHTML = `
    <i class="fas ${icon}" style="font-size: 1.2rem; color: ${type === 'success' ? '#34D399' : type === 'error' ? '#F87171' : '#60A5FA'};"></i>
    <div style="flex: 1; font-weight: 500;">${message}</div>
  `;

  container.appendChild(toast);
  playSoundFeedback(type);

  setTimeout(() => {
    toast.style.opacity = "0";
    toast.style.transform = "translateX(100%)";
    toast.style.transition = "all 0.3s ease";
    setTimeout(() => toast.remove(), 300);
  }, 4200);
}

// Current User State
export let currentUser = null;
export let userRole = null; // 'student' | 'admin' | null
export let studentProfile = null;

// View Switching Helper
export function switchView(viewId) {
  document.querySelectorAll(".view-container").forEach(view => {
    view.classList.remove("active");
  });

  const target = document.getElementById(viewId);
  if (target) {
    target.classList.add("active");
    window.scrollTo({ top: 0, behavior: "smooth" });
  }

  updateNavbar();
}

export function updateNavbar() {
  const userBadge = document.getElementById("navUserBadge");
  const userEmail = document.getElementById("navUserEmail");
  const logoutBtn = document.getElementById("navLogoutBtn");

  if (currentUser) {
    if (userBadge) userBadge.style.display = "flex";
    if (userEmail) userEmail.textContent = currentUser.email || "User";
    if (logoutBtn) logoutBtn.style.display = "inline-flex";
  } else {
    if (userBadge) userBadge.style.display = "none";
    if (logoutBtn) logoutBtn.style.display = "none";
  }
}

// Student Login
export async function loginStudent(email, password) {
  if (!email || !password) {
    showToast("Please enter both email and password.", "error");
    return false;
  }

  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    currentUser = userCredential.user;
    userRole = "student";
    
    await fetchStudentProfile(currentUser.email);
    showToast("Welcome back! Logged in successfully.", "success");
    switchView("studentDashboardView");
    return true;
  } catch (error) {
    let msg = "Login failed: " + error.message;
    if (error.code === "auth/user-not-found" || error.code === "auth/invalid-credential") {
      msg = "Invalid email or password";
    } else if (error.code === "auth/wrong-password") {
      msg = "Incorrect password";
    } else if (error.code === "auth/invalid-email") {
      msg = "Invalid email address format";
    }
    showToast(msg, "error");
    return false;
  }
}

// Student Self Sign-Up / Register New Account
export async function registerStudentAccount(data, facePhotoData = "") {
  if (!data.email || !data.password || !data.name || !data.usn) {
    showToast("Please fill in all registration fields.", "error");
    return false;
  }

  if (data.password.length < 6) {
    showToast("Password must be at least 6 characters long.", "error");
    return false;
  }

  try {
    // 1. Create Firebase Auth user
    const userCredential = await createUserWithEmailAndPassword(auth, data.email.trim(), data.password);
    currentUser = userCredential.user;
    userRole = "student";

    const usnKey = data.usn.toUpperCase().trim();

    // 2. Save detailed Student profile in Firestore with registered face photo
    await setDoc(doc(db, "students", usnKey), {
      studentName: data.name.trim(),
      usn: usnKey,
      email: data.email.trim(),
      department: data.department || "Computer Science",
      semester: data.semester || "1",
      section: data.section || "A",
      collegeName: data.college || "Smart Attendance Institute",
      photoDataUrl: facePhotoData || "",
      createdAt: serverTimestamp()
    });

    studentProfile = {
      id: usnKey,
      studentName: data.name.trim(),
      usn: usnKey,
      email: data.email.trim(),
      department: data.department || "Computer Science",
      semester: data.semester || "1",
      section: data.section || "A",
      collegeName: data.college || "Smart Attendance Institute",
      photoDataUrl: facePhotoData || ""
    };

    showToast("Account created successfully! Welcome to Smart Attendance.", "success");
    switchView("studentDashboardView");
    return true;
  } catch (error) {
    let msg = "Registration failed: " + error.message;
    if (error.code === "auth/email-already-in-use") {
      msg = "An account with this email already exists. Please log in.";
    } else if (error.code === "auth/weak-password") {
      msg = "Password is too weak.";
    }
    showToast(msg, "error");
    return false;
  }
}

// Admin Login
export async function loginAdmin(email, password) {
  if (!email || !password) {
    showToast("Please enter admin email and password.", "error");
    return false;
  }

  try {
    const userCredential = await signInWithEmailAndPassword(auth, email, password);
    const user = userCredential.user;

    // Strict Admin email check
    if (user.email !== "admin@gmail.com") {
      await signOut(auth);
      showToast("Access denied: Admin accounts only.", "error");
      return false;
    }

    currentUser = user;
    userRole = "admin";
    showToast("Admin access granted. Welcome to Command Center.", "success");
    switchView("adminDashboardView");
    return true;
  } catch (error) {
    let msg = "Admin login failed: " + error.message;
    if (error.code === "auth/invalid-credential") {
      msg = "Invalid admin email or password";
    }
    showToast(msg, "error");
    return false;
  }
}

// Fetch student profile details from Firestore (Searches by email or USN)
export async function fetchStudentProfile(email) {
  if (!email) return;

  try {
    // 1. Try querying by email
    const q = query(collection(db, "students"), where("email", "==", email.trim()));
    const querySnap = await getDocs(q);

    if (!querySnap.empty) {
      const docSnap = querySnap.docs[0];
      studentProfile = { id: docSnap.id, ...docSnap.data() };
      console.log("Loaded student profile:", studentProfile.studentName, "Has Photo:", !!studentProfile.photoDataUrl);
      return;
    }

    // 2. Fallback: try direct USN doc lookup
    const usnKey = email.split("@")[0].toUpperCase();
    const docRef = doc(db, "students", usnKey);
    const directSnap = await getDoc(docRef);

    if (directSnap.exists()) {
      studentProfile = { id: directSnap.id, ...directSnap.data() };
    } else {
      studentProfile = null;
    }
  } catch (e) {
    console.warn("Could not fetch student profile document:", e);
    studentProfile = null;
  }
}

// Official Face ID Biometric Enrollment for current student
export async function enrollStudentFace(photoDataUrl) {
  if (!currentUser || !photoDataUrl) {
    showToast("Please sign in and capture a clear face photo.", "error");
    return false;
  }

  try {
    const usnKey = (studentProfile?.usn || studentProfile?.id || currentUser.email.split("@")[0]).toUpperCase();
    
    await setDoc(doc(db, "students", usnKey), {
      studentName: studentProfile?.studentName || currentUser.email.split("@")[0],
      usn: usnKey,
      email: currentUser.email,
      department: studentProfile?.department || "CSE",
      semester: studentProfile?.semester || "1",
      section: studentProfile?.section || "A",
      collegeName: studentProfile?.collegeName || "Smart Attendance Institute",
      photoDataUrl: photoDataUrl,
      updatedAt: serverTimestamp()
    }, { merge: true });

    if (!studentProfile) {
      studentProfile = { usn: usnKey, email: currentUser.email };
    }
    studentProfile.photoDataUrl = photoDataUrl;

    showToast("Official Face ID registered successfully! This is now your permanent biometric ID.", "success");
    playSoundFeedback("success");
    return true;
  } catch (e) {
    console.error("Error enrolling face:", e);
    showToast("Failed to register Face ID: " + e.message, "error");
    return false;
  }
}

// Global Sign Out
export async function handleSignOut() {
  try {
    await signOut(auth);
    currentUser = null;
    userRole = null;
    studentProfile = null;
    showToast("Logged out successfully.", "info");
    switchView("roleSelectionView");
  } catch (error) {
    showToast("Logout failed: " + error.message, "error");
  }
}

// Live Clock & Status in Navbar
export function startLiveNavbarClock() {
  const clockEl = document.getElementById("navLiveClock");
  if (!clockEl) return;

  function update() {
    const now = new Date();
    clockEl.textContent = now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' });
  }
  update();
  setInterval(update, 1000);
}

// Setup Auth State Listener
export function initAuthListener(onUserChanged) {
  startLiveNavbarClock();

  onAuthStateChanged(auth, async (user) => {
    currentUser = user;
    if (user) {
      if (user.email === "admin@gmail.com") {
        userRole = "admin";
      } else {
        userRole = "student";
        await fetchStudentProfile(user.email);
      }
    } else {
      userRole = null;
      studentProfile = null;
    }
    updateNavbar();
    if (onUserChanged) onUserChanged(currentUser, userRole);
  });
}
