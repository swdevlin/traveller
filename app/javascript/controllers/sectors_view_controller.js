import { Controller } from '@hotwired/stimulus'

export default class extends Controller {
  static targets = ['listPanel', 'chartPanel', 'listBtn', 'chartBtn', 'chartCell', 'chartContainer', 'chartWrapper']
  static values = { campaignSlug: String }

  connect() {
    const mode = localStorage.getItem(this.modeKey()) || 'list';
    this.applyMode(mode);

    this.sectorsFrame = document.getElementById('sectors');
    this.frameLoadHandler = (e) => this.onFrameLoad(e);
    this.sectorsFrame?.addEventListener('turbo:frame-load', this.frameLoadHandler);

    if (mode === 'list') {
      this.maybeRestorePage();
    } else {
      requestAnimationFrame(() => {
        this.fitChartToViewport();
        this.centerChart();
      });
    }

    this.dragging = false;
    this.dragStartX = 0;
    this.dragStartY = 0;
    this.scrollStartX = 0;
    this.scrollStartY = 0;
    this.didDrag = false;

    this.onMouseDown = (e) => this.dragStart(e);
    this.onMouseMove = (e) => this.dragMove(e);
    this.onMouseUp = (e) => this.dragEnd(e);

    this.onDragStartNative = (e) => e.preventDefault();

    if (this.hasChartContainerTarget) {
      this.chartContainerTarget.addEventListener('mousedown', this.onMouseDown);
      this.chartContainerTarget.addEventListener('dragstart', this.onDragStartNative);
      window.addEventListener('mousemove', this.onMouseMove);
      window.addEventListener('mouseup', this.onMouseUp);
    }

    this.resizeHandler = () => this.fitChartToViewport();
    window.addEventListener('resize', this.resizeHandler);
  }

  disconnect() {
    this.sectorsFrame?.removeEventListener('turbo:frame-load', this.frameLoadHandler);
    if (this.hasChartContainerTarget) {
      this.chartContainerTarget.removeEventListener('mousedown', this.onMouseDown);
      this.chartContainerTarget.removeEventListener('dragstart', this.onDragStartNative);
    }
    window.removeEventListener('mousemove', this.onMouseMove);
    window.removeEventListener('mouseup', this.onMouseUp);
    window.removeEventListener('resize', this.resizeHandler);
    document.body.classList.remove('sectors-chart-mode');
  }

  dragStart(e) {
    if (e.button !== 0) return;
    this.dragging = true;
    this.didDrag = false;
    this.dragStartX = e.clientX;
    this.dragStartY = e.clientY;
    this.scrollStartX = this.chartContainerTarget.scrollLeft;
    this.scrollStartY = this.chartContainerTarget.scrollTop;
    this.chartContainerTarget.style.cursor = 'grabbing';
    this.chartContainerTarget.style.userSelect = 'none';
  }

  dragMove(e) {
    if (!this.dragging) return;
    const dx = e.clientX - this.dragStartX;
    const dy = e.clientY - this.dragStartY;
    if (Math.abs(dx) > 4 || Math.abs(dy) > 4) this.didDrag = true;
    this.chartContainerTarget.scrollLeft = this.scrollStartX - dx;
    this.chartContainerTarget.scrollTop = this.scrollStartY - dy;
  }

  dragEnd(e) {
    if (!this.dragging) return;
    this.dragging = false;
    this.chartContainerTarget.style.cursor = '';
    this.chartContainerTarget.style.userSelect = '';
    if (this.didDrag) {
      window.addEventListener('click', (ev) => ev.preventDefault(), { once: true, capture: true });
    }
  }

  showList() {
    this.applyMode('list');
    this.maybeRestorePage();
  }

  showChart() {
    this.applyMode('chart');
    requestAnimationFrame(() => {
      this.fitChartToViewport();
      this.centerChart();
    });
  }

  fitChartToViewport() {
    if (!this.hasChartWrapperTarget) return;
    const footer = document.querySelector('footer');
    const footerHeight = footer ? footer.offsetHeight : 0;
    const top = this.chartWrapperTarget.getBoundingClientRect().top;
    const height = window.innerHeight - top - footerHeight;
    this.chartWrapperTarget.style.height = `${Math.max(height, 200)}px`;
  }

  jumpToSector(event) {
    const name = event.target.value.trim();
    const cell = this.chartCellTargets.find(c => c.dataset.sectorName === name);
    if (!cell) return;
    this.chartCellTargets.forEach(c => c.classList.remove('chart-cell-active'));
    cell.classList.add('chart-cell-active');
    const cx = parseInt(cell.dataset.cx);
    const cy = parseInt(cell.dataset.cy);
    localStorage.setItem(this.chartCenterKey(), JSON.stringify({ cx, cy }));
    this.scrollContainerToCenter(cell, 'smooth');
    event.target.value = '';
  }

  setCenterAndNavigate(event) {
    const cx = parseInt(event.currentTarget.dataset.cx);
    const cy = parseInt(event.currentTarget.dataset.cy);
    if (!isNaN(cx) && !isNaN(cy)) {
      localStorage.setItem(this.chartCenterKey(), JSON.stringify({ cx, cy }));
    }
    if (this.hasChartContainerTarget) {
      const { scrollLeft, scrollTop } = this.chartContainerTarget;
      localStorage.setItem(this.chartScrollKey(), JSON.stringify({ scrollLeft, scrollTop }));
    }
  }

  applyMode(mode) {
    localStorage.setItem(this.modeKey(), mode);
    const isList = mode === 'list';
    this.listPanelTarget.classList.toggle('hidden', !isList);
    this.chartPanelTarget.classList.toggle('hidden', isList);
    this.listBtnTarget.classList.toggle('bg-panel-muted', isList);
    this.listBtnTarget.classList.toggle('text-fg-bright', isList);
    this.listBtnTarget.classList.toggle('text-fg-muted', !isList);
    this.chartBtnTarget.classList.toggle('bg-panel-muted', !isList);
    this.chartBtnTarget.classList.toggle('text-fg-bright', !isList);
    this.chartBtnTarget.classList.toggle('text-fg-muted', isList);
    document.body.classList.toggle('sectors-chart-mode', !isList);
    this.syncTourSteps(isList);
  }

  syncTourSteps(isList) {
    ['new-sector-blank', 'new-sector-import'].forEach(step => {
      const listEl = this.listPanelTarget.querySelector(`[data-tour-step="${step}"], [data-tour-step-inactive="${step}"]`);
      const chartEl = this.chartPanelTarget.querySelector(`[data-tour-step="${step}"], [data-tour-step-inactive="${step}"]`);

      if (listEl) {
        if (isList) {
          listEl.setAttribute('data-tour-step', step);
          listEl.removeAttribute('data-tour-step-inactive');
        } else {
          listEl.removeAttribute('data-tour-step');
          listEl.setAttribute('data-tour-step-inactive', step);
        }
      }

      if (chartEl) {
        if (!isList) {
          chartEl.setAttribute('data-tour-step', step);
          chartEl.removeAttribute('data-tour-step-inactive');
        } else {
          chartEl.removeAttribute('data-tour-step');
          chartEl.setAttribute('data-tour-step-inactive', step);
        }
      }
    });
  }

  maybeRestorePage() {
    const urlPage = new URLSearchParams(window.location.search).get('page');
    if (urlPage) {
      localStorage.setItem(this.pageKey(), urlPage);
      return;
    }
    const stored = localStorage.getItem(this.pageKey());
    if (stored && stored !== '1' && this.sectorsFrame) {
      const url = new URL(window.location.href);
      url.searchParams.set('page', stored);
      this.sectorsFrame.src = url.toString();
    }
  }

  onFrameLoad(event) {
    const src = event.target.src;
    if (!src) return;
    const page = new URL(src).searchParams.get('page') || '1';
    localStorage.setItem(this.pageKey(), page);
  }

  centerChart() {
    const savedScroll = JSON.parse(localStorage.getItem(this.chartScrollKey()) || 'null');
    if (savedScroll && this.hasChartContainerTarget) {
      this.chartContainerTarget.scrollLeft = savedScroll.scrollLeft;
      this.chartContainerTarget.scrollTop = savedScroll.scrollTop;
      const stored = JSON.parse(localStorage.getItem(this.chartCenterKey()) || 'null');
      if (stored && this.hasChartCellTarget) {
        const target = this.chartCellTargets.find(c =>
          parseInt(c.dataset.cx) === stored.cx && parseInt(c.dataset.cy) === stored.cy
        );
        if (target) {
          this.chartCellTargets.forEach(c => c.classList.remove('chart-cell-active'));
          target.classList.add('chart-cell-active');
        }
      }
      return;
    }

    const stored = JSON.parse(localStorage.getItem(this.chartCenterKey()) || 'null');
    let target;

    if (stored && this.hasChartCellTarget) {
      target = this.chartCellTargets.find(c =>
        parseInt(c.dataset.cx) === stored.cx &&
        parseInt(c.dataset.cy) === stored.cy
      );
    }

    if (!target && this.hasChartCellTarget) {
      const xs = this.chartCellTargets.map(c => parseInt(c.dataset.cx));
      const ys = this.chartCellTargets.map(c => parseInt(c.dataset.cy));
      const midX = Math.round((Math.min(...xs) + Math.max(...xs)) / 2);
      const midY = Math.round((Math.min(...ys) + Math.max(...ys)) / 2);
      target = this.chartCellTargets.reduce((best, c) => {
        const d = Math.abs(parseInt(c.dataset.cx) - midX) + Math.abs(parseInt(c.dataset.cy) - midY);
        const bd = Math.abs(parseInt(best.dataset.cx) - midX) + Math.abs(parseInt(best.dataset.cy) - midY);
        return d < bd ? c : best;
      });
    }

    if (target) {
      this.chartCellTargets.forEach(c => c.classList.remove('chart-cell-active'));
      target.classList.add('chart-cell-active');
      this.scrollContainerToCenter(target);
    }
  }

  scrollContainerToCenter(target, behavior = 'instant') {
    const container = this.chartContainerTarget;
    const containerRect = container.getBoundingClientRect();
    const targetRect = target.getBoundingClientRect();
    const scrollLeft = container.scrollLeft + targetRect.left - containerRect.left - (containerRect.width - targetRect.width) / 2;
    const scrollTop = container.scrollTop + targetRect.top - containerRect.top - (containerRect.height - targetRect.height) / 2;
    container.scrollTo({ left: scrollLeft, top: scrollTop, behavior });
  }

  modeKey() { return `sectors_view_mode_${this.campaignSlugValue}`; }
  pageKey() { return `sectors_list_page_${this.campaignSlugValue}`; }
  chartCenterKey() { return `sectors_chart_center_${this.campaignSlugValue}`; }
  chartScrollKey() { return `sectors_chart_scroll_${this.campaignSlugValue}`; }
}
