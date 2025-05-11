;; Customer Profile Contract
;; Manages shopper profiles

(define-data-var admin-principal principal tx-sender)

;; Map of customer profiles
(define-map customer-profile-map principal
  {
    profile-created: uint,
    profile-active: bool,
    profile-sharing: bool,
    profile-updated: uint
  }
)

;; Map from principal to ID
(define-map customer-id-map principal (buff 32))

;; Counter for generating unique IDs
(define-data-var id-counter-var uint u0)

;; Public function for customers to register
(define-public (register-customer-profile)
  (begin
    (asserts! (not (is-customer-registered tx-sender)) (err u1)) ;; Error if already registered

    ;; Create ID using hash of tx-sender and current counter
    (let ((customer-id (sha256 (concat (unwrap-panic (to-consensus-buff? tx-sender))
                                    (unwrap-panic (to-consensus-buff? (var-get id-counter-var)))))))

      ;; Update counter for next registration
      (var-set id-counter-var (+ (var-get id-counter-var) u1))

      ;; Store customer profile
      (map-set customer-profile-map tx-sender
        {
          profile-created: (unwrap-panic (get-block-info? time u0)),
          profile-active: true,
          profile-sharing: false,
          profile-updated: (unwrap-panic (get-block-info? time u0))
        }
      )

      ;; Store ID
      (map-set customer-id-map tx-sender customer-id)

      (ok customer-id)
    )
  )
)

;; Public function for customers to update sharing status
(define-public (update-customer-sharing (share-preferences bool))
  (begin
    (asserts! (is-customer-registered tx-sender) (err u2)) ;; Must be registered

    (let ((current-data (unwrap! (map-get? customer-profile-map tx-sender) (err u3))))
      (map-set customer-profile-map tx-sender
        (merge current-data {
          profile-sharing: share-preferences,
          profile-updated: (unwrap-panic (get-block-info? time u0))
        })
      )
    )
    (ok true)
  )
)

;; Public function for customer to deactivate account
(define-public (deactivate-customer-profile)
  (begin
    (asserts! (is-customer-registered tx-sender) (err u2)) ;; Must be registered

    (let ((current-data (unwrap! (map-get? customer-profile-map tx-sender) (err u3))))
      (map-set customer-profile-map tx-sender
        (merge current-data {
          profile-active: false,
          profile-updated: (unwrap-panic (get-block-info? time u0))
        })
      )
    )
    (ok true)
  )
)

;; Read-only function to check if customer exists
(define-read-only (is-customer-registered (address principal))
  (is-some (map-get? customer-profile-map address))
)

;; Read-only function to check if customer is active
(define-read-only (is-customer-active (address principal))
  (match (map-get? customer-profile-map address)
    profile (get profile-active profile)
    false
  )
)

;; Read-only function to check if customer shares preferences
(define-read-only (does-customer-share (address principal))
  (match (map-get? customer-profile-map address)
    profile (get profile-sharing profile)
    false
  )
)

;; Read-only function to get ID (only returns to owner)
(define-read-only (get-my-customer-id)
  (map-get? customer-id-map tx-sender)
)

;; Helper function to check if caller is admin
(define-private (is-customer-admin)
  (is-eq tx-sender (var-get admin-principal))
)
