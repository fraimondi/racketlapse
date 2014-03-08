;; Franco, 8 March 2014

;; Include this module and call it with
;; (takeTimeLapse "someName" minutes interval)
;; where minutes is the duration in minutes and interval is 
;; the interval between pictures in seconds

#lang racket/base

(require racket/system)
(require racket/date)
(require racket/format)

(provide takeTimeLapse)


;; Some parameters for raspistill
(define imageWidth "1920")
(define imageHeight "1080")
(define raspiOptions " --nopreview -t 2 --metering average --sharpness 20 -v")
;; You need to create the following dir, if it does not exist!
(define rootDir "/home/pi/stopmotions/")
(define outputDir rootDir)

;; This is the first part of the raspistill command to take pictures.
;; We then add the file name (in the loop below) and
;; finally we add the suffix
(define pic-command-prefix (string-append "raspistill -w " imageWidth 
                       " -h " imageHeight raspiOptions 
                       " -o " ))

(define pic-command-suffix ".jpeg 2> /dev/null")


;; Command to create a .avi file from the images (logic as above)
(define mencoder-command-prefix (string-append
                          "mencoder -nosound -ovc lavc -lavcopts vcodec=mpeg4:aspect=16/9:vbitrate=8000000"
                          " -vf scale=1920:1080 -mf type=jpeg:fps=24 mf://@"
                          rootDir "list.txt -o "))


;; A simple loop to take a picture every "interval"
;; seconds for "howmanytimes". 
(define counter 0)
(define (pictureLoop howmanytimes interval)
  (printf "DEBUG: taking picture number ~a\n" counter)
  (define command (string-append pic-command-prefix outputDir "img-" 
            (number->string (date-year (current-date)))
            (~a (number->string (date-month (current-date))) 
	       #:min-width 2 #:align 'right #:left-pad-string "0")
            (~a (number->string (date-day (current-date)))
	       #:min-width 2 #:align 'right #:left-pad-string "0")
            (~a (number->string (date-hour (current-date)))
	       #:min-width 2 #:align 'right #:left-pad-string "0")
            (~a (number->string (date-minute (current-date)))
	       #:min-width 2 #:align 'right #:left-pad-string "0")
            (~a (number->string (date-second (current-date)))
	       #:min-width 2 #:align 'right #:left-pad-string "0")
	    pic-command-suffix))
  (printf "DEBUG: I'm going to run: ~a\n" command)
  (system command)
  (cond ( (> howmanytimes 0) 
          (sleep interval)
          (set! howmanytimes (- howmanytimes 1))
          (set! counter (+ 1 counter))
          (pictureLoop howmanytimes interval)
          )
  )
)

;; Take a time lapse for a total of "minutes", with 
;; a picture every "interval", and saves the pics in
;; a newly created folder "name"

(define (takeTimeLapse name minutes interval)
  (set! outputDir (string-append rootDir name "/"))
  (printf "DEBUG: Starting the time lapse, saving images in ~a\n" outputDir)
  ;; If we can create the directory, we start taking pictures
  (cond ( (not (directory-exists? outputDir))
          (make-directory outputDir)
          (pictureLoop (/ (* minutes 60) interval) interval)
          )
        ;; FIXME: add an else condition and fail if dir. exists
        ) ;; End of the picture taking loop
  
  (printf "DEBUG: Time lapse ended; I took ~a pictures.\n" counter)
  ;; When we finish taking pics, we put everything together
  (printf "DEBUG: Creating .avi file, please wait...\n")
  (system (string-append "ls " outputDir "*.jpeg > " rootDir "list.txt"))
  (system (string-append mencoder-command-prefix 
                         outputDir "movie.avi"))
  (printf "DEBUG: File created, thank you\n")
)  
