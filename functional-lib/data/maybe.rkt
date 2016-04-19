#lang curly-fn racket/base

(require racket/require
         (multi-in data [functor applicative monad])
         (multi-in racket [contract generic match])
         (for-syntax racket/base
                     syntax/parse))

(provide maybe? just just? nothing nothing?
         maybe from-maybe)

(define (maybe? x)
  (or (just? x) (nothing? x)))

(struct just (value)
  #:transparent
  #:methods gen:functor
  [(define (map f x)
     (just (f (just-value x))))]
  #:methods gen:applicative
  [(define/generic -apply apply)
   (define (pure _ x) (just x))
   (define/contract (apply f args)
     (any/c (listof maybe?) . -> . any/c)
     (if (andmap just? args)
         (just (-apply (just-value f) (map just-value args)))
         nothing))]
  #:methods gen:monad
  [(define (chain f x)
     (f (just-value x)))])

(define nothing-value
  (let ()
    (struct nothing ()
      #:methods gen:custom-write
      [(define (write-proc x out mode)
         (display "#<nothing>" out))]
      #:methods gen:functor
      [(define (map f x) nothing-value)]
      #:methods gen:applicative
      [(define (pure _ x) (just x))
       (define (apply f args)
         nothing-value)]
      #:methods gen:monad
      [(define (chain f x) nothing-value)])
    (define nothing-value (nothing))
    nothing-value))

(define-match-expander nothing
  (syntax-parser [(_)        #'(== nothing-value)])
  (syntax-parser [(_ . args) #'(nothing-value . args)]
                 [_          #'nothing-value]))

(define nothing? #{eq? nothing})

(define/match (maybe x f m)
  [(_ f (just x))  (f x)]
  [(x _ (nothing)) x])

(define/match (from-maybe x m)
  [(_ (just x))  x]
  [(x (nothing)) x])