import { useEffect, useMemo, useState } from 'react'

type HealthState = 'checking' | 'ok' | 'degraded' | 'unreachable'

export function ApiHealthBadge() {
  const [status, setStatus] = useState<HealthState>('checking')
  const apiBaseUrl = useMemo(() => import.meta.env.VITE_API_BASE_URL, [])

  useEffect(() => {
    let isActive = true
    let inFlightController: AbortController | null = null

    const checkApi = async () => {
      inFlightController?.abort()
      inFlightController = new AbortController()

      try {
        const response = await fetch(`${apiBaseUrl}/healthz`, {
          cache: 'no-store',
          signal: inFlightController.signal,
        })

        if (!isActive) {
          return
        }

        if (response.ok) {
          setStatus('ok')
        } else {
          setStatus('degraded')
        }
      } catch {
        if (isActive) {
          setStatus('unreachable')
        }
      }
    }

    void checkApi()

    const intervalId = window.setInterval(() => {
      if (!document.hidden) {
        void checkApi()
      }
    }, 30_000)

    return () => {
      isActive = false
      inFlightController?.abort()
      window.clearInterval(intervalId)
    }
  }, [apiBaseUrl])

  const dotClassName =
    status === 'ok' ? 'dot ok' : status === 'degraded' || status === 'unreachable' ? 'dot bad' : 'dot'

  const text =
    status === 'ok'
      ? 'API status: OK'
      : status === 'degraded'
        ? 'API status: degraded'
        : status === 'unreachable'
          ? 'API status: unreachable'
          : 'API status: checking…'

  return (
    <span className="pill">
      <span className={dotClassName} />
      <span className="muted">{text}</span>
    </span>
  )
}