;;;;;;;[  Plan Drawing  ];;;;;;;;;;;;;;;;;;;;;;;;;
;;                                              ;;
;;  Draws centerline and top rail, places       ;;
;;  intermediate posts, and dimensions all.     ;;
;;                                              ;;
;;::::::::::::::::::::::::::::::::::::::::::::::;;
;;                                              ;;
;;  Author: J.D. Sandifer  (Copyright 2016)     ;;
;;  Written: 10/28/2015                         ;;
;;                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;                                              ;;
;;  11/08/2015                                  ;;
;;  - Added infill counting aspect to           ;;
;;    function.                                 ;;
;;                                              ;;
;;  11/09/2015                                  ;;
;;  - Began work on adding dimensions.          ;;
;;  - Changed RoundUpInt to use RoundUpTo       ;;
;;    (legacy support).                         ;;
;;                                              ;;
;;  11/10/2015                                  ;;
;;  - Added error handling function.            ;;
;;  - Added dimensioning feature.               ;;
;;  - Added infill stock list counting          ;;
;;    feature. This is starting to be awesome!  ;;
;;  - Added feature that changes dimension      ;;
;;    text into "EQ" and "(dim)" over "(#X)".   ;;
;;  - Added mline drawing & inserting end       ;;
;;    plates!!! (Requires TOP_RAIL mlstyle.)    ;;
;;                                              ;;
;;  11/16/2015                                  ;;
;;  - Added user input back.                    ;;
;;                                              ;;
;;  12/02/2015 - JD                             ;;
;;  - Added rubber band feature to point        ;;
;;    picking.                                  ;;
;;  - Changed endplate insertion to railLayer.  ;;
;;                                              ;;
;;  01/19/2016                                  ;;
;;  - Dimension label is now at second-to-last  ;;
;;    dim (just distance on a single dim).      ;;
;;  - Moved helper functions to separate file.  ;;
;;                                              ;;
;;  03/31/2016                                  ;;
;;  - Added post call-out placement.            ;;
;;                                              ;;
;;  04/04/2016                                  ;;
;;  - Made post tag placement conditional.      ;;
;;    (Only does it if it's a cable railing.)   ;;
;;                                              ;;
;;  04/13/2016                                  ;;
;;  - Changed filename to DRAW_PLAN.            ;;
;;                                              ;;
;;  05/03/2016                                  ;;
;;  - Made end plate placement conditional.     ;;
;;    (Only does it if flag is true - setup     ;;
;;    for Series 100 railing.)                  ;;
;;                                              ;;
;;  06/15/2016                                  ;;
;;  - Revised cable drawing for pline with      ;;
;;    width, offsetting first point, and        ;;
;;    placing threaded terminal.                ;;
;;                                              ;;
;;  08/01/2016                                  ;;
;;  - Added basic menu and dynamic function     ;;
;;    programming so "dp" always loads menu     ;;
;;    or runs the command if the menu has been  ;;
;;    already been seen.                        ;;
;;                                              ;;
;;  08/02/2016                                  ;;
;;  - Completed basic menu with spacing, type,  ;;
;;    and intermediade post type.               ;;
;;                                              ;;
;;  Todo:                                       ;;
;;  - Combine with PlanDrawGoal & Comm w/       ;;
;;    appropriate options.                      ;;
;;  - Revise copy on prompts.                   ;;
;;  - Check for endplate block, top_rail        ;;
;;    mline, and current layers and blocks.     ;;
;;                                              ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Runs menu tool and then gets redefined to run the drawing command with
;; the newly selected options.

(defun C:dp ( / )
	(C:dps))


	
;; Runs menu tool and then gets redefined to run the drawing command with
;; the newly selected options.

(defun C:dps ( / postSpacing railWidth intPostBlock layerStyle)

	(setq postSpacing 48   ; defaults
			railWidth "3"		
	      intPostBlock "BP"
			layerStyle "Residential"
			toggleHash nil)
			
	(JD:PutHash "Rail" T 'toggleHash)
	(JD:PutHash "Center Line" T 'toggleHash)
	(JD:PutHash "Posts" T 'toggleHash)
	(JD:PutHash "Dimensions" T 'toggleHash)
	(JD:PutHash "End Plates" T 'toggleHash)

	; Run dialog box to get user input
	; Warn if dialog fails and exit
	; Define a function based on the input so settings are
	;   saved and can be easily repeated without choices needed each time
	
	(setq setupDCLID (load_dialog "DrawPlanSetup.dcl"))
	
	(if (not (new_dialog "DrawPlanSetup" setupDCLID))
		(princ "\nDialog box not found in file!\n")
		;(exit)
		)
		
   ;; Post spacing action tiles
	(action_tile "spacing48"
		"(setq postSpacing 48)")
	(action_tile "spacing60"
		"(setq postSpacing 60)")
	(action_tile "spacing72"
		"(setq postSpacing 72)")		
	(action_tile "spacing"
		"(cond
			((= (type (read $value)) 'INT)
			 (setq postSpacing (atoi $value))
			 (set_tile \"spacingOther\" \"1\"))
			(T
			 (alert \"Post spacing must be a whole number.\")))")
		
	;; Top rail type action tiles
	(action_tile "s100"
		"(setq railWidth \"2\")")
	(action_tile "s200"
		"(setq railWidth \"3-1/2\")")
	(action_tile "s200X"
		"(setq railWidth \"3\")")
	(action_tile "s300"
		"(setq railWidth \"3\")")
	(action_tile "s300X"
		"(setq railWidth \"3\")")
	(action_tile "s320X"
		"(setq railWidth \"3\")")
	(action_tile "s350X"
		"(setq railWidth \"3-3/4\")")
	(action_tile "s500"
		"(setq railWidth \"5\")")
	(action_tile "woodAdapter"
		"(setq railWidth \"2-11/16\")")
		
	;; Intermediate post type action tiles
	(action_tile "postFascia"
		"(setq intPostBlock \"FB\")")
	(action_tile "postSurface"
		"(setq intPostBlock \"BP\")")	
	(action_tile "postFasciaTrimline"
		"(setq intPostBlock \"FBT\")")	
	(action_tile "postSurfaceTrimline"
		"(setq intPostBlock \"BPT\")")
	(action_tile "postFascia1100"
		"(setq intPostBlock \"FB-1100\")")		
		
	;; Layer style action tiles
	(action_tile "residentialLayers"
		"(setq layerStyle \"Residential\")")
	(action_tile "commercialLayers"
		"(setq layerStyle \"Commercial\")")
		
	;; Drawing toggles action tiles
	(action_tile "railToggle"
		"(if (= $value \"0\")
			(JD:PutHash \"Rail\" nil 'toggleHash)
			(JD:PutHash \"Rail\" T 'toggleHash))")
	(action_tile "centerLineToggle"
		"(if (= $value \"0\")
			(JD:PutHash \"Center Line\" nil 'toggleHash)
			(JD:PutHash \"Center Line\" T 'toggleHash))")
	(action_tile "postToggle"
		"(if (= $value \"0\")
			(JD:PutHash \"Posts\" nil 'toggleHash)
			(JD:PutHash \"Posts\" T 'toggleHash))")	
	(action_tile "dimensionToggle"
		"(if (= $value \"0\")
			(JD:PutHash \"Dimensions\" nil 'toggleHash)
			(JD:PutHash \"Dimensions\" T 'toggleHash))")
		
	;; OK/Cancel choice action tiles	
	(action_tile "accept" "(done_dialog)(setq userChoice T)")
	(action_tile "cancel" "(done_dialog)(setq userChoice nil)")
	
	(start_dialog)
	(unload_dialog setupDCLID)
	
	(if (not userChoice)
		(exit))
		

	(setq functionDefinition (strcat
		"(defun C:dp ( / ) 
			(DrawPlan " (itoa postSpacing) " \"" railWidth "\" \"" intPostBlock "\"
							\"" layerStyle "\" toggleHash)
			(princ))"))
	;(princ functionDefinition)
	(eval (read functionDefinition))
		
	(C:dp)
	(princ))



;; Variable managenment function - run by dp

(defun DrawPlan (postSpacing railWidth intPostBlock layerStyle toggleHash
							/ *error* ctrLineLayer postLayer dimLayer dimOffset 
							snapMode infillStockLength 
							isCableRailing isPicketRailing cableOffsetDistance
							tagOffsetDistance tagLayer tagBlock cableLayer 
							placeDims placeEndPlates placePosts placeCenteLine
							tagScale cableEndShortening placeRail)
	
	; Sets the default error handler to a custom one, localization above
	; causes it to be reset after this function finishes
	(setq *error* ErrorHandler)
	
   ; Save system variables and change to needed values
   (JD:ClearVars 'systemVariables)
   (JD:Save&ChangeVar "cmdEcho" 'systemVariables 0)
	(command "._UNDO" "_Begin")		; Start UNDO group
	
   (JD:Save&ChangeVar "attreq" 'systemVariables 0)
   (JD:Save&ChangeVar "blipmode" 'systemVariables 0)
   (JD:SaveVar "osmode" 'systemVariables)
   (JD:SaveVar "clayer" 'systemVariables)
   
	
	(princ "Layer style: ")(princ layerStyle)
	(JD:PrintHash 'toggleHash)
   ; Set block names
   ;(setq intPostBlock "BP"
	(setq	endPlateBlock "end_plate"
			tagBlock "POST-DRILLED CALL-OUT")
			
	; layer names
   (cond
			((= layerStyle "Residential")
				(setq ctrLineLayer "Center"
						postLayer "Detail"
						dimLayer "Dims"
						railLayer "Detail"
						tagLayer "POST-TAG"
						cableLayer "Cable"))
						
		   ((= layerStyle "Commercial")
				(setq ctrLineLayer "A-HRAL-CNTR"
						postLayer "A-HRAL-POST"
						dimLayer "Dims"
						railLayer "A-HRAL-RAIL"
						tagLayer "POST-TAG"
						cableLayer "Cable")))
			
	; and other options
   (setq dimOffset (itoa (- 30)))		; String means easy concatenation later
	(setq	tagOffsetDistance 9
			tagScale 1
			cableOffsetDistance 9
			cableEndShortening 5
			snapMode 64)
	
	; rail options
	;(setq postSpacing 72)
	;(setq railWidth "2-11/16")		; String or integer works here
	
	; Set flags to control whether certain things are drawn
	(setq isCableRailing nil
			isPicketRailing nil
			placeDims (JD:GetHash "Dimensions" 'toggleHash)
			placeEndPlates (JD:GetHash "End Plates" 'toggleHash)
			placePosts (JD:GetHash "Posts" 'toggleHash)
			placeCenteLine (JD:GetHash "Center Line" 'toggleHash)
			placeRail (JD:GetHash "Rail" 'toggleHash))
   
   (PlanDrawTool)			; Actual work done in this function

   (command "._UNDO" "_End")		; End UNDO group
   (JD:ResetAllVars 'systemVariables)
	
   (princ))			; Hide last return value (clean exit)



;;; Actual plan drawing tool

(defun PlanDrawTool ( /  Pt1 Pt2 centerLine
		       spaces lineLength infillLength
		       lineAngle isFirstTime pointList)

   (setvar "osmode" snapMode)
   (setq Pt1 (getpoint "\nChoose first point:"))
   (setq pointList (list Pt1))
   (setq isFirstTime "True")
	
   ; (Start loop for drawing each run)
   (while (/= (setq Pt2 (getpoint Pt1 "\nChoose next point:")) nil)
      ;; Keep a list of the selected points for later use
		(setq pointList (append pointList (list Pt2)))
      
		;; Change snap mode so it doesn't interfere with auto-drawing
		(setvar "osmode" 0)

		;; Main calculations
      (setq lineAngle (angle Pt1 Pt2))
      (setq lineLength (distance Pt1 Pt2))
      (setq spaces (RoundUpInt (/ lineLength postSpacing)))
		(setq spaceLength (/ lineLength spaces))
		
		;; Insert the starting endplate if this is the first post
		(if (and isFirstTime placeEndPlates)
         (progn
            (setvar "clayer" railLayer)
            (command "._insert" endPlateBlock "y" railWidth "r" 
					(angtos (- lineAngle PI) 0 9) Pt1)
            (setq isFirstTime nil)))
      
		;; Place mid posts if needed
      (if (and (>= spaces 2) placePosts)
			(progn
				(setvar "clayer" postLayer)
				(command "line" Pt1 Pt2 "")
				(setq centerLine (entlast))
				(command "divide" centerLine "B" intPostBlock "Y" spaces)
				(entdel centerLine)))

      ;; This section sets up points for dimensions and draws them
		;; using a loop to go through segment by segment
      (setq currentPt Pt1)
		(setq currentPtList (list Pt1))
      (setq dimIndex spaces)	; spaces should always be at least 1
      (while (and (> dimIndex 0)
						(or placeCenteLine placeDims isCableRailing isPicketRailing))
         ;; Calculate next point and add it to the list for this section
			(setq nextPt (polar currentPt lineAngle spaceLength))
			(setq currentPtList (append currentPtList (list nextPt)))
			
			;; Draw the centerline (pline)
			(cond 
				(placeCenteLine
					(setvar "clayer" ctrLineLayer)
					(command "._pline" currentPt "W" 0 0 nextPt "")))
			
         (cond
				(placeDims
					(setq offsetString (strcat "@" dimOffset "<" 
												(angtos (- lineAngle (/ PI 2)) 0 9)))
					(setvar "clayer" dimLayer)
					(command "._dimaligned" currentPt nextPt offsetString)
					; Get last dimension.
					(setq lastDim (entget (entlast)))
					;; Is this the second-to-last one? If so use the full label.
					;; Otherwise, just label it "EQ". (Unless there's only one.)
					(cond
						((and (= dimIndex 1) (= spaces 1)))
						((= dimIndex 2)
							(setq label (strcat "<>\\X(" (itoa spaces) "X)"))
							(entmod (subst (cons 1 label) 
											   (assoc 1 lastDim)
												lastDim)))
						(T
							(entmod (subst (cons 1 "EQ") 
												(assoc 1 lastDim) 
												lastDim))))))
			
			
			;; add post call out for each intermediate post
			(cond
				(	(and (> dimIndex 1)	isCableRailing)
					(setq postTagPt (polar nextPt (+ (/ PI 2) lineAngle) 		
												  tagOffsetDistance))
					(setvar "clayer" tagLayer)
					(command "._insert" tagBlock "s" tagScale "r" 0 postTagPt))
					
				(	isPicketRailing
					(setq postTagPt 
						(polar
							(polar nextPt 
									 (+ (/ PI 2) lineAngle) 		
									 tagOffsetDistance)
							lineAngle
							(- 0 (/ spaceLength 2))))
					(setvar "clayer" tagLayer)
					(command "._insert" tagBlock "s" tagScale "r" 0 postTagPt)
					))
								
			; prep for next loop (dimensioning & call-outs on next segment)
			(setq currentPt nextPt)
			(setq dimIndex (1- dimIndex)))
			
		;; Draw centerline (pline) - when I figure out how to feed in the pts
		;(setvar "clayer" ctrLineLayer)
		;(command "._pline" currentPtList "")
      
      ;; Prep for next loop (next railing segment)
		(setq Pt1 Pt2)
      (setvar "osmode" snapMode))    

   (setvar "osmode" 0)
   
	(cond (placeEndPlates
		(setq insertAngle (angtos lineAngle 0 9))
		(setvar "clayer" railLayer)
		(command "._insert" endPlateBlock "y" railWidth "r" insertAngle Pt1)))

   (cond (placeRail
		(setvar "clayer" railLayer)
		(setq settingsList (list "_.mline" "justification" "zero" "scale" railWidth "style" "TOP_RAIL"))
		(setq settingsList (append settingsList pointList (list "")))
		(apply 'command settingsList)))
	
	(cond (isCableRailing
		(setvar "clayer" cableLayer)
		(DrawCableLine pointList cableOffsetDistance)))
   
   (setvar "dimzin" 8)
		
   (princ))
	
	
	
;|========={ Draw cable lines }=============|;
;| Draw polyline for cable run base on      |;
;| a provided point list and distance.      |;
;|------------------------------------------|;
;| Author: J.D. Sandifer    Rev: 03/31/2016 |;
;|==========================================|;

(defun DrawCableLine (pointList cableOffsetDistance / 
										  Pt1 Pt2 Pt3 lineAngle offsetAngle
										  Pt1offset Pt2offset lastPt1offset
										  lastLineAngle)

	(JD:ChangeVar "osmode" 0)
	
	(setq CABLE_WIDTH "3/8"
			TERMINAL_BLOCK "TERMINAL")
	
	(setq Pt1 (JD:CarCdr 'pointList))
	(setq Pt2 (JD:CarCdr 'pointList))
	
	(setq lineAngle (angle Pt1 Pt2))
	(setq offsetAngle (- lineAngle (/ PI 2)))
		
	(setq Pt1offset (polar
							(polar Pt1 offsetAngle cableOffsetDistance)
							(+ offsetAngle (/ PI 2)) 
							cableEndShortening))	
	(setq Pt2offset (polar Pt2 offsetAngle cableOffsetDistance))
	
	(command "._pline" Pt1offset "W" CABLE_WIDTH CABLE_WIDTH Pt2offset "")
	(command "._insert" TERMINAL_BLOCK "r" 
							(angtos lineAngle 0 9) "s" 1 Pt1offset)
	
	(setq lastPt1offset Pt2offset)
	(setq lastLineAngle lineAngle)
	(setq Pt1 Pt2)
	
	(foreach Pt2 pointList
		
		(setq lineAngle (angle Pt1 Pt2))
		(setq offsetAngle (- lineAngle (/ PI 2)))
		(setq oldOffsetAngle (- lastLineAngle (/ PI 2)))
		
		(setq Pt1offset (polar Pt1 offsetAngle cableOffsetDistance))
		(setq Pt2offset (polar Pt2 offsetAngle cableOffsetDistance))
		
		(JD:Arc Pt1 lastPt1offset Pt1offset)
		(command "._pline" Pt1offset "W" CABLE_WIDTH CABLE_WIDTH Pt2offset "")
		
		; Prep for next round
		(setq lastPt1offset Pt2offset)
		(setq lastLineAngle lineAngle)
		(setq Pt1 Pt2))
		
	(princ))

	
;|=========={ Get point list }==============|;
;| Get a series of points from the user     |;
;| and return a list of the points.         |;
;|------------------------------------------|;
;| Author: J.D. Sandifer    Rev: 03/22/2016 |;
;|==========================================|;


(defun GetPointList ( / selectedPoint lastPoint pointList)

	(setq selectedPoint (getpoint "\nChoose first point:"))
	(setq pointList (append pointlist (list selectedPoint)))
	(setq lastPoint selectedPoint)

	(while (/= 
		(setq selectedPoint (getpoint lastPoint "\nChoose next point:"))
		nil)
		(setq pointList (append pointlist (list selectedPoint)))
		(setq lastPoint selectedPoint))
      
	pointList)

 

;-------------------------------------------------------------------------;

(princ
   (strcat
      "\n:: DRAW_PLAN.lsp loaded. | \\U+00A9 J.D. Sandifer "
      (menucmd "m=$(edtime,0,yyyy)")
      " ::"))
(princ)

;-------------------------------------------------------------------------;
;                              End of File                                ;
;-------------------------------------------------------------------------;