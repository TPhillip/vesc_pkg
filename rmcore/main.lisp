(def light-can-id 205)
(def light-state 0)
(def signal-left 0)
(def signal-right 0)

(def brake-can-id 206)
(def brake-light-state 0)

(defun can-handler ()
    (loopwhile t
        (recv
            ((event-can-sid . ((? id) . (? data)))
                (cond
                    ((= id light-can-id) {
                        (setq light-state (bufget-u8 data 0))
                        (setq signal-left (bufget-u8 data 1))
                        (setq signal-right (bufget-u8 data 2))
                        (gpio-write 5 light-state)
                        (gpio-write 7 signal-left)
                        (gpio-write 8 signal-right)
                    })

                    ((= id brake-can-id) {
                        (setq brake-light-state (bufget-u8 data 0))
                        (gpio-write 6 brake-light-state)
                    })
                )
            )
            (_ nil)
        )
    )
)

(defun main () {
    ; LED and ADC enable
    (gpio-configure 10 'pin-mode-out)
    (gpio-write 10 1)
    
    ; Out 1 and Out 2
    (gpio-configure 5 'pin-mode-out)
    (gpio-configure 6 'pin-mode-out)
    (gpio-configure 7 'pin-mode-out)
    (gpio-configure 8 'pin-mode-out)
    
    (gpio-write 5 0) ;head/tail light
    (gpio-write 6 0) ;brake light
    (gpio-write 7 0) ;left signal
    (gpio-write 8 0) ;right signal

    ; register CAN listener
    (event-register-handler (spawn can-handler))
    (event-enable 'event-can-sid)
})

(image-save)
(main)