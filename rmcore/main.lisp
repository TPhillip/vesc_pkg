(def light-can-id 205)
(def light-state 0)
(def signal-left 0)
(def signal-right 0)

(def brake-can-id 206)

(def headlight-pin 5)
(def brake-pin 6)
(def l-indicator-pin 7)
(def r-indicator-pin 8)

(def brake-lever 0)
(def brake-lever-prev 0)
(def brake-esc 0)

(def ledbuf (rgbled-buffer 2 0 1))

(defun can-handler ()
    (loopwhile t
        (recv
            ((event-can-sid . ((? id) . (? data)))
                (cond
                    ((= id light-can-id) {
                        (setq light-state (bufget-u8 data 0))
                        (setq signal-left (bufget-u8 data 1))
                        (setq signal-right (bufget-u8 data 2))
                    })

                    ((= id brake-can-id) {
                        (setq brake-esc (bufget-u8 data 0))
                    })
                )
            )
            (_ nil)
        )
    )
)

(defun send-brake-lever ()
    (progn
        (var buf-can (bufcreate 8))
        (bufclear buf-can)
        (bufset-i8 buf-can 0 brake-lever)
        (can-send-sid 40 buf-can)
        (print "setng brake lever to" brake-lever)
    )   
)

(defun main () {
    (set-print-prefix "IO-")

    ; LED and ADC enable
    (gpio-configure 10 'pin-mode-out)
    (gpio-write 10 1)

    ; Out 1 and Out 2
    (gpio-configure 5 'pin-mode-out)
    (gpio-configure 6 'pin-mode-out)

    ; RGB LEDs on PCB
    (rgbled-init 2)
    (rgbled-color ledbuf 0 (color-make 0.2 0 0))
    (rgbled-color ledbuf 1 (color-make 0 0.2 0.0))
    (rgbled-update ledbuf)

    (gpio-configure headlight-pin 'pin-mode-out)
    (gpio-configure brake-pin 'pin-mode-out)
    (gpio-configure l-indicator-pin 'pin-mode-out)
    (gpio-configure r-indicator-pin 'pin-mode-out)

    (gpio-write headlight-pin 0)
    (gpio-write brake-pin 0)
    (gpio-write l-indicator-pin 0)
    (gpio-write r-indicator-pin 0)

    (gpio-configure 0 'pin-mode-in-pu)
    (gpio-configure 1 'pin-mode-in-pd)
    (gpio-configure 2 'pin-mode-in-pd)
    (gpio-configure 3 'pin-mode-in-pd)

    ; register CAN listener
    (event-register-handler (spawn can-handler))
    (event-enable 'event-can-sid)

    (loopwhile-thd 100 t {
        (setq brake-lever (gpio-read 0))
        (if (!= brake-lever brake-lever-prev) {
            (setq brake-lever-prev brake-lever)
            (send-brake-lever)
        })

        (gpio-write headlight-pin light-state)
        (gpio-write brake-pin (if (or (= brake-lever 1) (= brake-esc 1)) 1 0))
        (gpio-write l-indicator-pin signal-left)
        (gpio-write r-indicator-pin signal-right)
        (sleep 0.1)
    })
})

(image-save)
(main)