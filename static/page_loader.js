/**
 * SmartAttend — Page Transition Loader & Navigation Interceptor
 * Requirements:
 * 1. Global semi-transparent overlay (fixed, inset: 0, z-index: 9999)
 * 2. Frosted glass dark backdrop (backdrop-filter: blur(6px))
 * 3. SmartAttend SVG logo ('S' with pin below and green checkmark above) + handwriting stylus animation
 * 4. Localized typewriter effect (KK: "Жүктелуде...", RU: "Загрузка...", EN: "Loading...")
 * 5. Global controller: window.showLoader(), window.hideLoader()
 */

(function () {
  'use strict';

  let currentLang = 'kk';
  let typewriterInterval = null;
  let overlayEl = null;
  let textEl = null;
  let isLoaderVisible = false;

  const I18N_TEXTS = {
    kk: 'Жүктелуде...',
    kz: 'Жүктелуде...',
    ru: 'Загрузка...',
    en: 'Loading...'
  };

  function getLang() {
    try {
      const stored = localStorage.getItem('smartattend_lang') || localStorage.getItem('lang');
      if (stored) return stored.toLowerCase();
      const docLang = document.documentElement.lang;
      if (docLang) return docLang.toLowerCase();
    } catch (e) {}
    return 'kk';
  }

  function initOverlay() {
    if (document.getElementById('sa-page-loader-overlay')) {
      overlayEl = document.getElementById('sa-page-loader-overlay');
      textEl = document.getElementById('sa-loader-text');
      return;
    }

    const overlay = document.createElement('div');
    overlay.id = 'sa-page-loader-overlay';
    overlay.setAttribute('role', 'alert');
    overlay.setAttribute('aria-live', 'assertive');

    overlay.innerHTML = `
      <div class="sa-loader-sticker">
        <!-- SmartAttend Logo -->
        <div class="sa-loader-logo-wrap">
          <div class="sa-loader-logo-glow"></div>
          <img src="logo.png?v=real" alt="SmartAttend" class="sa-loader-logo-img" onerror="this.style.display='none'; document.getElementById('sa-svg-fallback').style.display='block';">
          <svg id="sa-svg-fallback" class="sa-loader-logo-svg" style="display:none;" viewBox="0 0 100 100" fill="none">
            <!-- Downward Blue Pointer Pin -->
            <defs>
              <linearGradient id="saPinGrad" x1="0%" y1="0%" x2="0%" y2="100%">
                <stop offset="0%" stop-color="#38BDF8"/>
                <stop offset="100%" stop-color="#1D4ED8"/>
              </linearGradient>
            </defs>
            <polygon points="42,56 58,56 50,88" fill="url(#saPinGrad)"/>
            <!-- Letter 'S' in bold white -->
            <path d="M 64 22 C 60 20 54 18 47 18 C 34 18 26 26 26 36 C 26 50 44 49 44 58 C 44 63 39 66 33 66 C 26 66 20 63 16 58 L 11 67 C 17 73 25 76 33 76 C 47 76 56 68 56 57 C 56 42 37 43 37 35 C 37 30 41 27 47 27 C 52 27 57 29 60 31 Z" fill="#FFFFFF"/>
            <!-- Green Checkmark -->
            <path d="M 48 32 L 58 43 L 78 20" stroke="#10B981" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>

        <!-- Handwriting Stylus and Text -->
        <div class="sa-loader-text-row">
          <span id="sa-loader-text" class="sa-loader-typewriter">Жүктелуде...</span>
          <div class="sa-loader-pen-holder">
            <svg class="sa-loader-pen-svg" viewBox="0 0 32 32" fill="none" xmlns="http://www.w3.org/2000/svg">
              <defs>
                <linearGradient id="saPenG" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" stop-color="#93C5FD"/>
                  <stop offset="50%" stop-color="#2563EB"/>
                  <stop offset="100%" stop-color="#1E40AF"/>
                </linearGradient>
              </defs>
              <!-- Stylus Body -->
              <path d="M25 4 L28 7 L12 23 L7 25 L9 20 Z" fill="url(#saPenG)" stroke="#BFDBFE" stroke-width="1"/>
              <!-- Nib -->
              <polygon points="7,25 4,28 9,26" fill="#38BDF8"/>
              <line x1="12" y1="23" x2="9" y2="20" stroke="#FFFFFF" stroke-width="1.2"/>
              <circle cx="4" cy="28" r="1.5" fill="#60A5FA"/>
            </svg>
          </div>
        </div>

        <div class="sa-loader-ink-line"></div>
      </div>
    `;

    document.body.appendChild(overlay);
    overlayEl = overlay;
    textEl = document.getElementById('sa-loader-text');
  }

  function startTypewriter(fullText) {
    if (typewriterInterval) clearInterval(typewriterInterval);
    if (!textEl) return;

    let index = 0;
    textEl.textContent = '';

    typewriterInterval = setInterval(() => {
      index++;
      if (index <= fullText.length) {
        textEl.textContent = fullText.slice(0, index);
      } else {
        // Pause briefly at the end then restart typewriter smoothly
        index = 0;
        textEl.textContent = '';
      }
    }, 110);
  }

  function stopTypewriter() {
    if (typewriterInterval) {
      clearInterval(typewriterInterval);
      typewriterInterval = null;
    }
  }

  /**
   * Show global loader
   * @param {string} [lang] - 'kk' | 'ru' | 'en'
   * @param {string} [customText] - Optional custom text
   */
  window.showLoader = function (lang, customText) {
    initOverlay();
    if (!overlayEl) return;

    const resolvedLang = lang || getLang();
    currentLang = resolvedLang;
    const targetText = customText || I18N_TEXTS[resolvedLang] || I18N_TEXTS['kk'];

    overlayEl.classList.remove('sa-hiding');
    overlayEl.classList.add('sa-active');
    isLoaderVisible = true;

    startTypewriter(targetText);
  };

  /**
   * Hide global loader
   */
  window.hideLoader = function () {
    if (!overlayEl || !isLoaderVisible) return;
    isLoaderVisible = false;

    overlayEl.classList.add('sa-hiding');
    setTimeout(() => {
      overlayEl.classList.remove('sa-active');
      overlayEl.classList.remove('sa-hiding');
      stopTypewriter();
    }, 150); // Exact 150ms fade-out
  };

  // Aliases
  window.showPageLoader = window.showLoader;
  window.hidePageLoader = window.hideLoader;

  /**
   * Helper to wrap asynchronous operations or transitions with the loader
   * @param {Function} asyncFn
   * @param {string} [lang]
   * @param {number} [minMs]
   */
  window.withPageLoader = async function (asyncFn, lang, minMs = 280) {
    window.showLoader(lang);
    const start = performance.now();
    try {
      if (typeof asyncFn === 'function') {
        await asyncFn();
      }
    } finally {
      const elapsed = performance.now() - start;
      const remaining = Math.max(0, minMs - elapsed);
      setTimeout(() => {
        window.hideLoader();
      }, remaining);
    }
  };

  // Auto-init DOM once ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initOverlay);
  } else {
    initOverlay();
  }
})();
