import { animate, createTimeline, stagger } from 'animejs'
import { prefersReducedMotion } from '@/lib/motion'

const EASE = 'inOut(2)'
const DURATION = 200

function revealInstantly(elements: Element | NodeListOf<Element> | null) {
  if (!elements) return
  const list = elements instanceof NodeList ? Array.from(elements) : [elements]
  for (const el of list) {
    if (el instanceof HTMLElement) {
      el.style.opacity = '1'
      el.style.transform = 'none'
    }
  }
}

export function animateCharacterEntrance(root: ParentNode) {
  const chrome = root.querySelector('[data-animate="chrome"]')
  const dock = root.querySelector('[data-animate="dock"]')

  if (prefersReducedMotion()) {
    revealInstantly(chrome)
    revealInstantly(dock)
    return
  }

  if (chrome) {
    animate(chrome, {
      opacity: [0, 1],
      translateY: [-10, 0],
      duration: DURATION,
      ease: EASE,
    })
  }

  if (dock) {
    animate(dock, {
      opacity: [0, 1],
      translateY: [24, 0],
      duration: DURATION + 20,
      delay: 50,
      ease: EASE,
    })
  }
}

export function animateSlotSelect(element: Element) {
  if (prefersReducedMotion()) return

  animate(element, {
    scale: [1, 1.012, 1],
    duration: 200,
    ease: EASE,
  })
}

export function animatePanelIn(element: Element) {
  if (prefersReducedMotion()) {
    revealInstantly(element)
    return
  }

  animate(element, {
    opacity: [0, 1],
    translateY: [12, 0],
    scale: [0.98, 1],
    duration: DURATION,
    ease: EASE,
  })
}

export function animatePanelOut(element: Element): Promise<void> {
  if (prefersReducedMotion()) {
    revealInstantly(element)
    return Promise.resolve()
  }

  return new Promise((resolve) => {
    animate(element, {
      opacity: [1, 0],
      translateY: [0, -8],
      scale: [1, 0.99],
      duration: 180,
      ease: EASE,
      onComplete: () => resolve(),
    })
  })
}

export function animateListItems(container: ParentNode, selector: string) {
  const items = container.querySelectorAll(selector)
  if (!items.length) return

  if (prefersReducedMotion()) {
    revealInstantly(items)
    return
  }

  animate(items, {
    opacity: [0, 1],
    translateY: [6, 0],
    duration: DURATION,
    delay: stagger(40, { start: 80 }),
    ease: EASE,
  })
}

export function animateFormFields(container: ParentNode) {
  const fields = container.querySelectorAll('[data-animate="field"]')
  if (!fields.length) return

  if (prefersReducedMotion()) {
    revealInstantly(fields)
    return
  }

  animate(fields, {
    opacity: [0, 1],
    translateY: [8, 0],
    duration: DURATION,
    delay: stagger(45, { start: 60 }),
    ease: EASE,
  })
}

export function animateUiClose(root: ParentNode) {
  const targets = root.querySelectorAll('[data-animate]')
  if (!targets.length) return

  if (prefersReducedMotion()) return

  animate(targets, {
    opacity: [1, 0],
    translateY: [0, 12],
    duration: 180,
    delay: stagger(25, { reversed: true }),
    ease: EASE,
  })
}

export function animateSpawnConfirm(element: Element): Promise<void> {
  if (prefersReducedMotion()) {
    if (element instanceof HTMLElement) element.style.opacity = '0'
    return Promise.resolve()
  }

  return new Promise((resolve) => {
    const timeline = createTimeline({ defaults: { ease: EASE } })

    timeline
      .add(element, {
        scale: [1, 0.98],
        duration: 100,
      })
      .add(element, {
        opacity: [1, 0],
        duration: 200,
        onComplete: () => resolve(),
      })
  })
}
