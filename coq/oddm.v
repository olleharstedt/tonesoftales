(* 	Excercises from Software Foundations 
		2013-10-04 *)

Inductive yesno : Set :=
| yes : yesno
| no : yesno.

Fixpoint even (n:nat) {struct n} : yesno :=
match n with
| O => yes
| S O => no
| S (S n') => even n'
end.

Inductive natlist : Type :=
| nil : natlist
| cons : nat -> natlist -> natlist.

Notation "x :: l" := (cons x l) (at level 60, right associativity).
Notation "[ x , .. , y ]" := (cons x .. (cons y nil) ..).
Notation "[ ]" := nil.

Fixpoint append (l1 l2 : natlist) {struct l1} : natlist := 
	match l1 with
	  | nil    => l2
	  | h :: t => h :: (append t l2)
  end.

(*Notation "x ++ y" := (append x y) (at level 59).*)

(* When we say that Coq comes with nothing built-in, we
   really mean it!  Even equality testing has to be
	    defined. *)
Fixpoint eqnat (m n : nat) {struct m} : yesno :=
	match m with 
		| O =>
			match n with 
				| O => yes
				| S n' => no
			end
		| S m' =>
			match n with
				| O => no
				| S n' => eqnat m' n'
			end
	end.

Fixpoint nonzeros (l : natlist) : natlist :=
	match l with
	| nil => nil
	| 0::x => nonzeros x
	| x::y => x :: nonzeros y
	end.

Fixpoint oddmembers (l : natlist) : natlist :=
	match l with
	| [] => []
	| x::y => 
		match (even x) with
		| yes => oddmembers(y)
		| no => x :: oddmembers(y)
		end
	end.

Example test_oddmembers: oddmembers [0,1,0,2,3,0,0] = [1,3].
simpl. reflexivity. Qed.

Fixpoint countodd (l : natlist) : nat :=
	match l with
	| [] => 0
	| x::y =>
		match (even x) with
		| yes => 0 + countodd(y)
		| no => 1 + countodd(y)
		end
	end.

Example test_countoddmembers1: countodd [1,0,3,1,4,5] = 4.
simpl. reflexivity. Qed.

Example test_countoddmembers2: countodd [0,2,4] = 0.
simpl. reflexivity. Qed.

Example test_countoddmembers3: countodd nil = 0.
simpl. reflexivity. Qed.

Fixpoint alternate (l1 l2 : natlist) : natlist :=
	match l1, l2 with
	| [], l => l
	| l, [] => l
	| x1::y1, x2::y2 =>
		x1 :: x2 :: alternate y1 y2
	end.

Example test_alternate1: alternate [1,2,3] [4,5,6] = [1,4,2,5,3,6].
simpl. reflexivity. Qed.

Example test_alternate2: alternate [1] [4,5,6] = [1,4,5,6].
simpl. reflexivity. Qed.

Example test_alternate3: alternate [1,2,3] [4] = [1,4,2,3].
simpl. reflexivity. Qed.

Example test_alternate4: alternate [] [20,30] = [20,30].
simpl. reflexivity. Qed.

Definition bag := natlist.

Fixpoint count_bag (v:nat) (s:bag) : nat :=
	match s with
	| [] => 0
	| y::tl =>
		match eqnat v y with
			| yes =>
				1 + count_bag v tl
			| no =>
				0 + count_bag v tl
			end
	end.


Example test_count1: count_bag 1 [1,2,3,1,4,1] = 3.
simpl. reflexivity. Qed.
 Example test_count2: count_bag 6 [1,2,3,1,4,1] = 0.
simpl. reflexivity. Qed.

Definition sum : bag -> bag -> bag := append.

Definition add (v : nat) (s : bag) : bag :=
	match v, s with
	| x, [] => [x]
	| x, l => x :: l
	end.

Theorem eqnat_ : forall x, eqnat x x = yes.
Proof.
intros.
simpl.
induction x.
	reflexivity.

	simpl.
	apply IHx.

	Qed.

(*Theorem countbag_ : forall b x, count_bag x b + 1 = S (count_bag x b).*)

(*Theorem bag_t : forall b x, count_bag x b + 1 = count_bag x (add x b).*)
