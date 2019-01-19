;
; get-put.scm -- The two halves of a query.
;
; The BindLink example showed how one can create a query, run it, and
; simulataneously use the query results to create new data in the
; AtomSpace. In fact, this process can be split into two: a "Get"
; part that performs the query, and a "Put" part that performs the
; graph re-writing.
;
; If BindLink is thought of as logical implication:
;	 For all x, P(x) implies Q(x)
; then GetLink is the first half:
;	 For all x, P(x) implies a set {all x that satisfy P(x)}
; while PutLink is the second half:
;	 Create the set {Q(x)} given some other set {x}
; The PutLink is a form of "beta-reduction" or "substitution" or
; "pasting": for each `x` in the set {x} it just pastes `x` into `Q(x)`.
;
; Every BindLink is equivalent to a Get-Put pair. This example
; demonstrates this explicitly.
;
; Spliting a query into a satisfying set, followed by a beta-reduction
; can sometimes allow a more flexible approach to managing the
; knowledgebase.
;
(use-modules (opencog) (opencog exec) (opencog query))

; Place some data into the atomspace. This is the same as in the
; BindLink example.
;
(Evaluation (Predicate "_obj") (List (Concept "make") (Concept "pottery")))
(Evaluation (Predicate "_obj") (List (Concept "make") (Concept "statue")))
(Evaluation (Predicate "_obj") (List (Concept "make") (Concept "brick")))

(Evaluation (Predicate "from") (List (Concept "make") (Concept "clay")))

; Create a query, an "inner join" of several interesting clauses.
;
; This searches for all triples (verb, thing, substance) that
; simultaneously satisfy two clauses:
;
;			_obj(verb, thing) AND from(verb, substance)
;
; This is an "inner join" because `verb` must be the same in both
; clauses.

(define get-satisfying-set
	(GetLink
		(VariableList	; Variable declaration (optional)
			(Variable "$verb")
			(Variable "$var0")
			(Variable "$var1")
		)

		; The distinct clauses are wrapped by an AndLink.
		(AndLink
			; Look for _obj($verb, $var0)
			(Evaluation
				(Predicate "_obj")
				(ListLink
					(Variable "$verb") ; This will match: (Concept "make")
					(Variable "$var0") ; This will match: (Concept "pottery")
				)
			)
			; Look for from($verb, $var1)
			(EvaluationLink
				(Predicate "from")
				(ListLink
					(Variable "$verb") ; This will match: (Concept "make")
					(Variable "$var1") ; This will match: (Concept "clay")
				)
			)
		)
	)
)

; Run the pattern matcher. This matches both required clauses,
; and creates a set of all matching results.
(cog-execute! get-satisfying-set)

; Optional: save the results from the query in a scheme variable.
; In general, this is discouraged; however, it will make this example
; easier to understand (we hope!)

(define the-sat-set (cog-execute! get-satisfying-set))

; Define a beta-reduction.
(define reduction-rule
	(PutLink
		; A veriable declaration is mandatory, whenever there are
		; more than one variables. It is required, so that one can
		; know the order (the sequence) of the variables. If there
		; is only one variable, it does not need to be declared.
		(VariableList	; Variable declaration (optional)
			(Variable "$verb")
			(Variable "$var0")
			(Variable "$var1"))

		; The "output" of the re-write; the `Q(x)` part of the
		; implication.
		(Evaluation
			(Predicate "make_from")
			(List (Variable "$var0") (Variable "$var1")))

		; The "input" to the re-write; some set of `x`'s that will
		; be pasted into `Q(x)`. This is just the set computed earlier.
		the-sat-set
	))

; Now, run the
