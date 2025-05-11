;; Retail Verification Contract
;; Validates legitimate merchants on the platform

(define-data-var admin-principal principal tx-sender)

;; Map of verified retailers with their details
(define-map verified-retail-map principal
  {
    retail-name: (string-utf8 100),
    retail-license: (string-utf8 50),
    retail-category: (string-utf8 50),
    retail-verified: bool,
    retail-date: uint
  }
)

;; Public function to register a retailer (anyone can request registration)
(define-public (register-retail-entity (retail-name (string-utf8 100)) (retail-license (string-utf8 50)) (retail-category (string-utf8 50)))
  (begin
    (asserts! (not (is-retail-registered tx-sender)) (err u1)) ;; Error if already registered
    (map-set verified-retail-map tx-sender
      {
        retail-name: retail-name,
        retail-license: retail-license,
        retail-category: retail-category,
        retail-verified: false,
        retail-date: u0
      }
    )
    (ok true)
  )
)

;; Admin-only function to verify a retailer
(define-public (verify-retail-entity (retailer principal))
  (begin
    (asserts! (is-retail-admin) (err u2)) ;; Only admin can verify
    (asserts! (is-retail-registered retailer) (err u3)) ;; Retailer must exist

    (let ((current-data (unwrap! (map-get? verified-retail-map retailer) (err u4))))
      (map-set verified-retail-map retailer
        (merge current-data {
          retail-verified: true,
          retail-date: (unwrap-panic (get-block-info? time u0))
        })
      )
    )
    (ok true)
  )
)

;; Admin-only function to revoke verification
(define-public (revoke-retail-entity (retailer principal))
  (begin
    (asserts! (is-retail-admin) (err u2)) ;; Only admin can revoke
    (asserts! (is-retail-registered retailer) (err u3)) ;; Retailer must exist

    (let ((current-data (unwrap! (map-get? verified-retail-map retailer) (err u4))))
      (map-set verified-retail-map retailer
        (merge current-data {
          retail-verified: false
        })
      )
    )
    (ok true)
  )
)

;; Admin-only function to change admin
(define-public (set-retail-admin (new-admin principal))
  (begin
    (asserts! (is-retail-admin) (err u2))
    (var-set admin-principal new-admin)
    (ok true)
  )
)

;; Read-only function to check if a principal is a verified retailer
(define-read-only (is-verified-retail-entity (address principal))
  (match (map-get? verified-retail-map address)
    retailer (get retail-verified retailer)
    false
  )
)

;; Read-only function to check if a retailer is registered
(define-read-only (is-retail-registered (address principal))
  (is-some (map-get? verified-retail-map address))
)

;; Read-only function to get retailer details
(define-read-only (get-retail-details (address principal))
  (map-get? verified-retail-map address)
)

;; Helper function to check if caller is admin
(define-private (is-retail-admin)
  (is-eq tx-sender (var-get admin-principal))
)
