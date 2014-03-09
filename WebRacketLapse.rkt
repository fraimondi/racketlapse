#lang racket/base

;; Franco 9 March 2014.
;; A simple Racket web server to launch time lapses. See comments in
;; takeTimeLapse.rkt
;; The main function to launch everything is at the bottom of this file.

(require racket/list)
(require web-server/servlet 
         web-server/servlet-env)
(require "takeTimeLapse.rkt")


(define PORTNUMBER 8000) ;; The port number for the web server
(define ENDPOINT_PATH "/WRL") ;; the servlet path

(define curJobName null) ;; If a job is running, this is not null
(define curJobDuration 10) ;; Job duration in minutes
(define curJobInterval 5) ;; Interval between pictures in the current job.

(define currentJobThread null) ;; The thread for the current job

;; FIXME: read it from takeTimeLapse (or pass as a parameter)!
(define rootDir "/home/pi/stopmotions/")

(define selectDuration 
  '(p "Duration" (select ((name "duration"))
                         (option ((value "2")) "2 min")
                         (option ((value "5")) "5 min")
                         (option ((value "15")) "15 min")
                         (option ((value "30")) "30 min")
                         (option ((value "60")) "1 hour")
                         (option ((value "120")) "2 hours")
                         (option ((value "240")) "4 hours")
                         (option ((value "480")) "8 hours"))))

(define selectInterval 
  '(p "Interval" (select ((name "interval"))
                         (option ((value "2")) "2 seconds")
                         (option ((value "5")) "5 seconds")
                         (option ((value "15")) "15 seconds")
                         (option ((value "30")) "30 seconds")
                         (option ((value "60")) "1 minute")
                         (option ((value "120")) "2 minutes")
                         )))

;; The workhorse. It takes a request and decides what to do.
;; FIXME: add checks for parameters etc. 
;; Honestly, this is just a quick hack...
(define (main-dispatcher req)
  (define bindings (request-bindings req))
  (cond ( (equal? null currentJobThread)
          (cond ( (exists-binding? 'name bindings) 
                  ;; There is a name parameter in the request, let's start a job
                  ;; FIXME: oh dear, you need to add a lot of error checking here!
                  (startJob req)
                  )
                (else ;; this is probably the first time we enter
                 (displayMainPage)
                 )
          )
          )
        (else ;; a job is running
         (response/xexpr 
          `(html (body (h1 "Racket Time Lapse Controller")
                (p "The following job is currently active:")
                ,(displayCurrentJob)
                )
                 )
          )
         ) ;; end else for job is running
        ) ;; end initial cond
  ) ;; end define
  
;; What it says...
(define (displayMainPage)
  (response/xexpr 
   `(html (body (h1 "Racket Time Lapse Controller")
                (p "Just fill in the details below and press submit to start a new job")
                (form 
                 (p "Enter a name for the job" (input ((name "name"))))
                 ,selectDuration
                 ,selectInterval
                 (p (input ((type "submit") (value "Submit"))))                
                 ) ;; end form
                (h2 "Completed jobs")
                ,(displayCompletedJobs)
                )
          )
  
  )
  )

;; FIXME: implement it :-)!
(define (displayCompletedJobs)
 ;; (define directories (filter-not file-exists? (directory-list rootDir)))
  '(p "Not yet implemented")
  )

;; What it says on the tin...
(define (displayCurrentJob)
  `(ul (li (b "Name: " ,curJobName))
     (li (b "Duration (minutes): " ,curJobDuration))
     (li (b "Interval (seconds): " ,curJobInterval))
     )
  )

;; We start a new time lapse job in a separate thread. See comments in 
;; takeTimeLapse.rkt for details about its implementation.
(define (startJob req)
  (define bindings (request-bindings req))
  ;; FIXME: add error checks, you lazy programmer!
  (set! curJobName (extract-binding/single 'name bindings))
  (set! curJobDuration (extract-binding/single 'duration bindings))
  (set! curJobInterval (extract-binding/single 'interval bindings)) 
  (set! currentJobThread (thread (lambda ()  (takeTimeLapse curJobName (string->number curJobDuration) (string->number curJobInterval)))))
  (response/xexpr 
   `(html (body (h1 "Racket Time Lapse Controller: job started")
                ,(displayCurrentJob))))
   
  )
;=================================================================================================================================================================
; The main function to launch the server
(define (main)
  (serve/servlet main-dispatcher 
                 #:listen-ip #f
                 #:port PORTNUMBER     
                 #:launch-browser? #f
                 #:servlet-path ENDPOINT_PATH
                 #:extra-files-paths
                  (list
                   (build-path "/home/pi/stopmotions"))
  )
) ;; end of main  

(main)