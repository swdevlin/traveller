export function applyTheme(theme) {
  document.cookie = `theme=${theme}; path=/; max-age=31536000; SameSite=Lax`;
  document.documentElement.dataset.theme = theme;
}

export function setTheme(theme) {
  applyTheme(theme);
  window.location.reload();
}