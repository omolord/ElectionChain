
;; title: ElectionChain
;; version: 1.0.0
;; summary: Secure blockchain voting solution for federal elections and congressional races
;; description: This contract provides a comprehensive voting system with election management,
;;              voter registration, secure ballot casting, and transparent vote tallying.

;; traits
;;

;; token definitions
;;

;; constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ELECTION_NOT_FOUND (err u101))
(define-constant ERR_ELECTION_NOT_ACTIVE (err u102))
(define-constant ERR_VOTER_NOT_REGISTERED (err u103))
(define-constant ERR_VOTER_ALREADY_VOTED (err u104))
(define-constant ERR_INVALID_CANDIDATE (err u105))
(define-constant ERR_ELECTION_ALREADY_EXISTS (err u106))
(define-constant ERR_ELECTION_ENDED (err u107))

;; data vars
(define-data-var next-election-id uint u1)

;; data maps

;; Election storage
(define-map elections
  uint ;; election-id
  {
    name: (string-ascii 100),
    description: (string-ascii 500),
    start-block: uint,
    end-block: uint,
    election-type: (string-ascii 50), ;; "federal", "congressional", "local"
    is-active: bool,
    total-votes: uint
  }
)

;; Candidates for each election
(define-map candidates
  {election-id: uint, candidate-id: uint}
  {
    name: (string-ascii 100),
    party: (string-ascii 50),
    description: (string-ascii 300),
    vote-count: uint
  }
)

;; Track candidate count per election
(define-map election-candidate-count
  uint ;; election-id
  uint ;; candidate-count
)

;; Registered voters
(define-map registered-voters
  principal ;; voter address
  {
    is-registered: bool,
    registration-block: uint,
    voter-id: (string-ascii 50) ;; external voter ID for verification
  }
)

;; Track which elections a voter has voted in
(define-map voter-elections
  {voter: principal, election-id: uint}
  {
    has-voted: bool,
    vote-block: uint,
    candidate-id: uint
  }
)

;; Election administrators
(define-map election-admins
  principal
  bool
)

;; public functions

;; Initialize contract - set contract owner as admin
(define-public (initialize)
  (begin
    (map-set election-admins CONTRACT_OWNER true)
    (ok true)
  )
)

;; Add election administrator
(define-public (add-admin (admin principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-set election-admins admin true)
    (ok true)
  )
)

;; Remove election administrator
(define-public (remove-admin (admin principal))
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (map-delete election-admins admin)
    (ok true)
  )
)

;; Create a new election
(define-public (create-election
  (name (string-ascii 100))
  (description (string-ascii 500))
  (start-block uint)
  (end-block uint)
  (election-type (string-ascii 50))
)
  (let
    (
      (election-id (var-get next-election-id))
    )
    (begin
      (asserts! (default-to false (map-get? election-admins tx-sender)) ERR_UNAUTHORIZED)
      (asserts! (is-none (map-get? elections election-id)) ERR_ELECTION_ALREADY_EXISTS)
      (asserts! (> end-block start-block) (err u108))

      (map-set elections election-id
        {
          name: name,
          description: description,
          start-block: start-block,
          end-block: end-block,
          election-type: election-type,
          is-active: true,
          total-votes: u0
        }
      )

      (map-set election-candidate-count election-id u0)
      (var-set next-election-id (+ election-id u1))
      (ok election-id)
    )
  )
)

;; Add candidate to election
(define-public (add-candidate
  (election-id uint)
  (name (string-ascii 100))
  (party (string-ascii 50))
  (description (string-ascii 300))
)
  (let
    (
      (election (unwrap! (map-get? elections election-id) ERR_ELECTION_NOT_FOUND))
      (candidate-count (default-to u0 (map-get? election-candidate-count election-id)))
      (candidate-id (+ candidate-count u1))
    )
    (begin
      (asserts! (default-to false (map-get? election-admins tx-sender)) ERR_UNAUTHORIZED)
      (asserts! (get is-active election) ERR_ELECTION_NOT_ACTIVE)
      (asserts! (< block-height (get start-block election)) ERR_ELECTION_NOT_ACTIVE)

      (map-set candidates {election-id: election-id, candidate-id: candidate-id}
        {
          name: name,
          party: party,
          description: description,
          vote-count: u0
        }
      )

      (map-set election-candidate-count election-id candidate-id)
      (ok candidate-id)
    )
  )
)

;; Register voter
(define-public (register-voter (voter-id (string-ascii 50)))
  (begin
    (map-set registered-voters tx-sender
      {
        is-registered: true,
        registration-block: block-height,
        voter-id: voter-id
      }
    )
    (ok true)
  )
)

;; Cast vote
(define-public (cast-vote (election-id uint) (candidate-id uint))
  (let
    (
      (election (unwrap! (map-get? elections election-id) ERR_ELECTION_NOT_FOUND))
      (voter-info (unwrap! (map-get? registered-voters tx-sender) ERR_VOTER_NOT_REGISTERED))
      (candidate (unwrap! (map-get? candidates {election-id: election-id, candidate-id: candidate-id}) ERR_INVALID_CANDIDATE))
      (existing-vote (map-get? voter-elections {voter: tx-sender, election-id: election-id}))
    )
    (begin
      (asserts! (get is-registered voter-info) ERR_VOTER_NOT_REGISTERED)
      (asserts! (get is-active election) ERR_ELECTION_NOT_ACTIVE)
      (asserts! (>= block-height (get start-block election)) ERR_ELECTION_NOT_ACTIVE)
      (asserts! (< block-height (get end-block election)) ERR_ELECTION_ENDED)
      (asserts! (is-none existing-vote) ERR_VOTER_ALREADY_VOTED)

      ;; Record the vote
      (map-set voter-elections {voter: tx-sender, election-id: election-id}
        {
          has-voted: true,
          vote-block: block-height,
          candidate-id: candidate-id
        }
      )

      ;; Update candidate vote count
      (map-set candidates {election-id: election-id, candidate-id: candidate-id}
        (merge candidate {vote-count: (+ (get vote-count candidate) u1)})
      )

      ;; Update total votes for election
      (map-set elections election-id
        (merge election {total-votes: (+ (get total-votes election) u1)})
      )

      (ok true)
    )
  )
)

;; End election
(define-public (end-election (election-id uint))
  (let
    (
      (election (unwrap! (map-get? elections election-id) ERR_ELECTION_NOT_FOUND))
    )
    (begin
      (asserts! (default-to false (map-get? election-admins tx-sender)) ERR_UNAUTHORIZED)
      (asserts! (get is-active election) ERR_ELECTION_NOT_ACTIVE)

      (map-set elections election-id
        (merge election {is-active: false})
      )
      (ok true)
    )
  )
)

;; read only functions

;; Get election details
(define-read-only (get-election (election-id uint))
  (map-get? elections election-id)
)

;; Get candidate details
(define-read-only (get-candidate (election-id uint) (candidate-id uint))
  (map-get? candidates {election-id: election-id, candidate-id: candidate-id})
)

;; Get voter registration status
(define-read-only (get-voter-info (voter principal))
  (map-get? registered-voters voter)
)

;; Check if voter has voted in election
(define-read-only (has-voter-voted (voter principal) (election-id uint))
  (match (map-get? voter-elections {voter: voter, election-id: election-id})
    vote-record (get has-voted vote-record)
    false
  )
)

;; Get election results
(define-read-only (get-election-results (election-id uint))
  (let
    (
      (election (map-get? elections election-id))
      (candidate-count (default-to u0 (map-get? election-candidate-count election-id)))
    )
    (match election
      election-data
        (some {
          election: election-data,
          candidate-count: candidate-count
        })
      none
    )
  )
)

;; Check if election is active and voting is open
(define-read-only (is-voting-open (election-id uint))
  (match (map-get? elections election-id)
    election
      (and
        (get is-active election)
        (>= block-height (get start-block election))
        (< block-height (get end-block election))
      )
    false
  )
)

;; Check if user is admin
(define-read-only (is-admin (user principal))
  (default-to false (map-get? election-admins user))
)

;; Get total number of candidates in election
(define-read-only (get-candidate-count (election-id uint))
  (default-to u0 (map-get? election-candidate-count election-id))
)

;; private functions

;; Verify election exists and is active
(define-private (verify-election-active (election-id uint))
  (match (map-get? elections election-id)
    election
      (and (get is-active election)
           (>= block-height (get start-block election))
           (< block-height (get end-block election)))
    false
  )
)
