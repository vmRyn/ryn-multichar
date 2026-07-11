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
  const sideLeft = root.querySelector('[data-animate="side-left"]')
  const sideRight = root.querySelector('[data-animate="side-right"]')

  if (prefersReducedMotion()) {
    revealInstantly(chrome)
    revealInstantly(dock)
    revealInstantly(sideLeft)
    revealInstantly(sideRight)
    return
  }

  if (chrome instanceof HTMLElement) chrome.style.pointerEvents = ''
  if (dock instanceof HTMLElement) dock.style.pointerEvents = ''
  if (sideLeft instanceof HTMLElement) sideLeft.style.pointerEvents = ''
  if (sideRight instanceof HTMLElement) sideRight.style.pointerEvents = ''

  if (chrome) {
    animate(chrome, {
      opacity: [0, 1],
      translateY: [-12, 0],
      duration: DURATION,
      ease: EASE,
    })
  }

  if (sideLeft) {
    animate(sideLeft, {
      opacity: [0, 1],
      translateX: [-18, 0],
      duration: DURATION + 20,
      delay: 40,
      ease: EASE,
    })
  }

  if (sideRight) {
    animate(sideRight, {
      opacity: [0, 1],
      translateX: [18, 0],
      duration: DURATION + 20,
      delay: 40,
      ease: EASE,
    })
  }

  if (dock) {
    animate(dock, {
      opacity: [0, 1],
      translateY: [20, 0],
      duration: DURATION + 20,
      delay: 50,
      ease: EASE,
    })
  }
}

export function animateSelectChromeOut(root: ParentNode): Promise<void> {
  const chrome = root.querySelector('[data-animate="chrome"]')
  const dock = root.querySelector('[data-animate="dock"]')
  const sideLeft = root.querySelector('[data-animate="side-left"]')
  const sideRight = root.querySelector('[data-animate="side-right"]')
  const targets = [chrome, sideLeft, sideRight, dock].filter(Boolean) as HTMLElement[]

  if (!targets.length) return Promise.resolve()

  if (prefersReducedMotion()) {
    for (const el of targets) {
      el.style.opacity = '0'
      el.style.pointerEvents = 'none'
    }
    return Promise.resolve()
  }

  return new Promise((resolve) => {
    let completed = 0
    const onDone = () => {
      completed += 1
      if (completed >= targets.length) resolve()
    }

    for (const el of targets) {
      el.style.pointerEvents = 'none'
    }

    if (chrome) {
      animate(chrome, {
        opacity: [1, 0],
        translateY: [0, -12],
        duration: 180,
        ease: EASE,
        onComplete: onDone,
      })
    }

    if (sideLeft) {
      animate(sideLeft, {
        opacity: [1, 0],
        translateX: [0, -18],
        duration: 200,
        delay: 20,
        ease: EASE,
        onComplete: onDone,
      })
    }

    if (sideRight) {
      animate(sideRight, {
        opacity: [1, 0],
        translateX: [0, 18],
        duration: 200,
        delay: 20,
        ease: EASE,
        onComplete: onDone,
      })
    }

    if (dock) {
      animate(dock, {
        opacity: [1, 0],
        translateY: [0, 20],
        duration: 200,
        delay: 30,
        ease: EASE,
        onComplete: onDone,
      })
    }
  })
}

export function animateSelectChromeIn(root: ParentNode) {
  animateCharacterEntrance(root)
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

export function animateSpawnEntrance(root: ParentNode) {
  const title = root.querySelector('[data-animate="spawn-title"]')
  const rail = root.querySelector('[data-animate="spawn-rail"]')
  const choices = root.querySelectorAll('[data-animate="spawn-choice"]')
  const actions = root.querySelector('[data-animate="spawn-actions"]')

  if (prefersReducedMotion()) {
    revealInstantly(title)
    revealInstantly(rail)
    revealInstantly(choices)
    revealInstantly(actions)
    return
  }

  if (title) {
    animate(title, {
      opacity: [0, 1],
      translateX: [-24, 0],
      translateY: [-8, 0],
      duration: 320,
      ease: 'out(3)',
    })
  }

  if (rail) {
    animate(rail, {
      opacity: [0, 1],
      translateX: [36, 0],
      duration: 380,
      delay: 60,
      ease: 'out(3)',
    })
  }

  if (choices.length) {
    animate(choices, {
      opacity: [0, 1],
      translateX: [16, 0],
      translateY: [8, 0],
      duration: 280,
      delay: stagger(45, { start: 160 }),
      ease: 'out(2)',
    })
  }

  if (actions) {
    animate(actions, {
      opacity: [0, 1],
      translateY: [14, 0],
      duration: 300,
      delay: 220 + Math.min(choices.length, 6) * 35,
      ease: 'out(2)',
    })
  }
}

export function animateSpawnChoiceSelect(element: Element) {
  if (prefersReducedMotion()) return

  animate(element, {
    scale: [1, 1.02, 1],
    duration: 220,
    ease: EASE,
  })
}
