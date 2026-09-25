// ============================================================
// FIREBASE CONFIGURATION & INITIALIZATION
// ============================================================

import { initializeApp } from "https://www.gstatic.com/firebasejs/10.12.2/firebase-app.js";
import { 
  getAuth, 
  signInWithEmailAndPassword, 
  signOut, 
  onAuthStateChanged,
  createUserWithEmailAndPassword,
  sendPasswordResetEmail 
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-auth.js";
import { 
  getFirestore, 
  collection, 
  doc, 
  setDoc, 
  addDoc, 
  getDoc, 
  getDocs, 
  query, 
  where, 
  orderBy, 
  onSnapshot, 
  serverTimestamp,
  deleteDoc,
  updateDoc
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore.js";
import { 
  getStorage, 
  ref, 
  uploadString, 
  getDownloadURL 
} from "https://www.gstatic.com/firebasejs/10.12.2/firebase-storage.js";

// Firebase credentials for smartattendance-8eb16
const firebaseConfig = {
  apiKey: "AIzaSyCnCwoze6fxwO2wMuw6Eqy1HpVQCu4KQwY",
  authDomain: "smartattendance-8eb16.firebaseapp.com",
  projectId: "smartattendance-8eb16",
  storageBucket: "smartattendance-8eb16.firebasestorage.app",
  messagingSenderId: "932587802880",
  appId: "1:932587802880:web:0c743f8aa214f1bbf9a3e5"
};

// Initialize Firebase
const app = initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);
const storage = getStorage(app);

export { 
  app, 
  auth, 
  db, 
  storage,
  // Auth methods
  signInWithEmailAndPassword,
  signOut,
  onAuthStateChanged,
  createUserWithEmailAndPassword,
  sendPasswordResetEmail,
  // Firestore methods
  collection,
  doc,
  setDoc,
  addDoc,
  getDoc,
  getDocs,
  query,
  where,
  orderBy,
  onSnapshot,
  serverTimestamp,
  deleteDoc,
  updateDoc,
  // Storage methods
  ref,
  uploadString,
  getDownloadURL
};
