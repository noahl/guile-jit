/* classes: h_files */

#ifndef TAGSH
#define TAGSH
/*	Copyright (C) 1995,1996, 1997 Free Software Foundation, Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA
 *
 * As a special exception, the Free Software Foundation gives permission
 * for additional uses of the text contained in its release of GUILE.
 *
 * The exception is that, if you link the GUILE library with other files
 * to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the GUILE library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the
 * Free Software Foundation under the name GUILE.  If you copy
 * code from other Free Software Foundation releases into a copy of
 * GUILE, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for GUILE, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.  */


/** This file defines the format of SCM values and cons pairs.
 ** It is here that tag bits are assigned for various purposes.
 **/



/* In the beginning was the Word:
 */
typedef long SCM;



/* Cray machines have pointers that are incremented once for each word,
 * rather than each byte, the 3 most significant bits encode the byte
 * within the word.  The following macros deal with this by storing the
 * native Cray pointers like the ones that looks like scm expects.  This
 * is done for any pointers that might appear in the car of a scm_cell, pointers
 * to scm_vector elts, functions, &c are not munged.
 */
#ifdef _UNICOS
# define SCM2PTR(x) ((int)(x) >> 3)
# define PTR2SCM(x) (((SCM)(x)) << 3)
# define SCM_POINTERS_MUNGED
#else
# define SCM2PTR(x) (x)
# define PTR2SCM(x) ((SCM)(x))
#endif /* def _UNICOS */


/* SCM variables can contain:
 *
 * Non-objects -- meaning that the tag-related macros don't apply to them
 * in the usual way.
 *
 * Immediates -- meaning that the variable contains an entire Scheme object.
 *
 * Non-immediates -- meaning that the variable holds a (possibly
 * tagged) pointer into the cons pair heap.
 *
 * Non-objects are distinguished from other values by careful coding
 * only (i.e., programmers must keep track of any SCM variables they
 * create that don't contain ordinary scheme values).
 *
 * All immediates and non-immediates must have a 0 in bit 0.  Only
 * non-object values can have a 1 in bit 0.  In some cases, bit 0 of a
 * word in the heap is used for the GC tag so during garbage
 * collection, that bit might be 1 even in an immediate or
 * non-immediate value.  In other cases, bit 0 of a word in the heap
 * is used to tag a pointer to a GLOC (VM global variable address) or
 * the header of a struct.  But whenever an SCM variable holds a
 * normal Scheme value, bit 0 is 0.
 *
 * Immediates and non-immediates are distinguished by bits two and four.
 * Immediate values must have a 1 in at least one of those bits.  Does
 * this (or any other detail of tagging) seem arbitrary?  Try changing it!
 * (Not always impossible but it is fair to say that many details of tags
 * are mutually dependent).  */

#define SCM_IMP(x) 		(6 & (int)(x))
#define SCM_NIMP(x) 		(!SCM_IMP(x))

/* Here is a summary of tagging in SCM values as they might occur in
 * SCM variables or in the heap.
 *
 * low bits    meaning
 *
 *
 * 0		Most objects except...
 * 1 		...glocs and structs (this tag valid only in a SCM_CAR or
 *		in the header of a struct's data).
 *
 * 00		heap addresses and many immediates (not integers)
 * 01		glocs/structs, some tc7_ codes
 * 10		immediate integers
 * 11		various tc7_ codes including, tc16_ codes.
 *
 *
 * 000		heap address
 * 001		glocs/structs
 * 010		integer
 * 011		closure
 * 100		immediates
 * 101		tc7_
 * 110 		integer
 * 111		tc7_
 *
 *
 * 100 --- IMMEDIATES
 *
 * Looking at the seven final bits of an immediate:
 *
 * 0000-100	short instruction
 * 0001-100	short instruction
 * 0010-100	short instruction
 * 0011-100	short instruction
 * 0100-100	short instruction
 * 0101-100	short instruction
 * 0110-100	various immediates and long instructions
 * 0111-100	short instruction
 * 1000-100	short instruction
 * 1001-100	short instruction
 * 1010-100	short instruction
 * 1011-100	short instruction
 * 1100-100	short instruction
 * 1101-100	short instruction
 * 1110-100	immediate characters
 * 1111-100	ilocs
 *
 * Some of the 0110100 immediates are long instructions (they dispatch
 * in two steps compared to one step for a short instruction).
 * The two steps are, (1) dispatch on 7 bits to the long instruction
 * handler, (2) dispatch on 7 additional bits.
 *
 * One way to think of it is that there are 128 short instructions,
 * with the 13 immediates above being some of the most interesting.
 *
 * Also noteworthy are the groups of 16 7-bit instructions implied by
 * some of the 3-bit tags.   For example, closure references consist
 * of an 8-bit aligned address tagged with 011.  There are 16 identical 7-bit
 * instructions, all ending 011, which are invoked by evaluating closures.
 *
 * In other words, if you hand the evaluator a closure, the evaluator
 * treats the closure as a graph of virtual machine instructions.
 * A closure is a pair with a pointer to the body of the procedure
 * in the CDR and a pointer to the environment of the closure in the CAR.
 * The environment pointer is tagged 011 which implies that the least
 * significant 7 bits of the environment pointer also happen to be
 * a virtual machine instruction we could call "SELF" (for self-evaluating
 * object).
 *
 * A less trivial example are the 16 instructions ending 000.  If those
 * bits tag the CAR of a pair, then evidently the pair is an ordinary
 * cons pair and should be evaluated as a procedure application.  The sixteen,
 * 7-bit 000 instructions are all "NORMAL-APPLY"  (Things get trickier.
 * For example, if the CAR of a procedure application is a symbol, the NORMAL-APPLY
 * instruction will, as a side effect, overwrite that CAR with a new instruction
 * that contains a cached address for the variable named by the symbol.)
 *
 * Here is a summary of tags in the CAR of a non-immediate:
 *
 *   HEAP CELL:	G=gc_mark; 1 during mark, 0 other times.
 *
 * cons	   ..........SCM car..............0  ...........SCM cdr.............G
 * gloc    ..........SCM vcell..........001  ...........SCM cdr.............G
 * struct  ..........void * type........001  ...........void * data.........G
 * closure ..........SCM code...........011  ...........SCM env.............G
 * tc7	   .........long length....Gxxxx1S1  ..........void *data............
 *
 *
 *
 * 101 & 111 --- tc7_ types
 *
 *		tc7_tags are 7 bit tags ending in 1x1.  These tags
 *		occur only in the CAR of heap cells, and have the
 *		handy property that all bits of the CAR above the
 *		bottom eight can be used to store a length, thus
 *		saving a word in the body itself.  Thus, we use them
 *		for strings, symbols, and vectors (among other
 *		things).
 *
 *		SCM_LENGTH returns the bits in "length" (see the diagram).
 *		SCM_CHARS returns the data cast to "char *"
 *		SCM_CDR returns the data cast to "SCM"
 *		TYP7(X) returns bits 0...6 of SCM_CAR (X)
 *
 *		For the interpretation of SCM_LENGTH and SCM_CHARS
 *		that applies to a particular type, see the header file
 *		for that type.
 *
 *              Sometimes we choose the bottom seven bits carefully,
 *              so that the 2-valued bit (called S bit) can be masked
 *              off to reveal a common type.
 *
 *		TYP7S(X) returns TYP7, but masking out the option bit S.
 *
 *              For example, all strings have 0010 in the 'xxxx' bits
 *              in the diagram above, the S bit says whether it's a
 *              substring.
 *
 *		for example:
 *						        S
 *			scm_tc7_string    	= G0010101
 *			scm_tc7_substring	= G0010111
 *
 *		TYP7S turns both string tags into tc7_string; thus,
 *		testing TYP7S against tc7_string is a quick way to
 *		test for any kind of string, shared or unshared.
 *
 *		Some TC7 types are subdivided into 256 subtypes giving
 *		rise to the macros:
 *
 *		TYP16
 *		TYP16S
 *		GCTYP16
 *
 *		TYP16S functions similarly wrt to TYP16 as TYP7S to TYP7,
 *		but a different option bit is used (bit 2 for TYP7S,
 *		bit 8 for TYP16S).
 * */




/* {Non-immediate values.}
 *
 * If X is non-immediate, it is necessary to look at SCM_CAR (X) to
 * figure out Xs type.  X may be a cons pair, in which case the value
 * SCM_CAR (x) will be either an immediate or non-immediate value.  X
 * may be something other than a cons pair, in which case the value
 * SCM_CAR (x) will be a non-object value.
 *
 * All immediates and non-immediates have a 0 in bit 0.  We
 * additionally preserve the invariant that all non-object values
 * stored in the SCM_CAR of a non-immediate object have a 1 in bit 1:
 */

#define SCM_NCONSP(x) (1 & (int)SCM_CAR(x))
#define SCM_CONSP(x) (!SCM_NCONSP(x))


/* SCM_ECONSP should be used instead of SCM_CONSP at places where GLOCS
 * can be expected to occur.
 */
#define SCM_ECONSP(x) (SCM_CONSP (x) \
		       || (SCM_TYP3(x) == 1 \
                           && SCM_CDR (SCM_CAR (x) - 1) != 0))
#define SCM_NECONSP(x) (SCM_NCONSP(x) \
			&& (SCM_TYP3(x) != 1 \
			    || SCM_CDR (SCM_CAR (x) - 1) == 0))



#define SCM_CELLP(x) 	(!SCM_NCELLP(x))
#define SCM_NCELLP(x) 	((sizeof(scm_cell)-1) & (int)(x))

/* See numbers.h for macros relating to immediate integers.
 */

#define SCM_ITAG3(x) 		(7 & (int)x)
#define SCM_TYP3(x) 		(7 & (int)SCM_CAR(x))
#define scm_tc3_cons		0
#define scm_tc3_cons_gloc	1
#define scm_tc3_int_1		2
#define scm_tc3_closure		3
#define scm_tc3_imm24		4
#define scm_tc3_tc7_1		5
#define scm_tc3_int_2		6
#define scm_tc3_tc7_2		7


/*
 * Do not change the three bit tags.
 */


#define SCM_TYP7(x) 		((int)SCM_CAR(x) & 0x7f)
#define SCM_TYP7S(x) 		((int)SCM_CAR(x) & (0x7f & ~2))


#define SCM_TYP16(x) 		(0xffff & (int)SCM_CAR(x))
#define SCM_TYP16S(x) 		(0xfeff & (int)SCM_CAR(x))
#define SCM_GCTYP16(x) 		(0xff7f & (int)SCM_CAR(x))



/* Testing and Changing GC Marks in Various Standard Positions
 */
#define SCM_GCMARKP(x) 		(1 & (int)SCM_CDR(x))
#define SCM_GC8MARKP(x) 	(0x80 & (int)SCM_CAR(x))
#define SCM_SETGCMARK(x) 	SCM_SETOR_CDR (x,1)
#define SCM_CLRGCMARK(x) 	SCM_SETAND_CDR (x, ~1L)
#define SCM_SETGC8MARK(x) 	SCM_SETOR_CAR (x, 0x80)
#define SCM_CLRGC8MARK(x) 	SCM_SETAND_CAR (x, ~0x80L)




/* couple */
#define scm_tc7_ssymbol		5
#define scm_tc7_msymbol		7

/* couple */
#define scm_tc7_vector		13
#define scm_tc7_wvect		15

/* couple */
#define scm_tc7_string		21
#define scm_tc7_substring	23

/* 29 and 31 are free! */

/* Many of the following should be turned
 * into structs or smobs.  We need back some
 * of these 7 bit tags!
 */
#define scm_tc7_uvect		37
#define scm_tc7_lvector		39
#define scm_tc7_fvect		45
#define scm_tc7_dvect		47
#define scm_tc7_cvect		53
#define scm_tc7_svect		55
#define scm_tc7_contin		61
#define scm_tc7_cclo		63
#define scm_tc7_rpsubr		69
#define scm_tc7_bvect		71
#define scm_tc7_byvect		77
#define scm_tc7_ivect		79
#define scm_tc7_subr_0		85
#define scm_tc7_subr_1		87
#define scm_tc7_cxr		93
#define scm_tc7_subr_3		95
#define scm_tc7_subr_2		101
#define scm_tc7_asubr		103
#define scm_tc7_subr_1o		109
#define scm_tc7_subr_2o		111
#define scm_tc7_lsubr_2		117
#define scm_tc7_lsubr		119


/* There are 256 port subtypes.  Here are the first four.
 * These must agree with the init function in ports.c
 */
#define scm_tc7_port		125

/* fports and pipes form an intended TYP16S equivelancy
 * group (similar to a tc7 "couple".
 */
#define scm_tc16_fport 		(scm_tc7_port + 0*256L)
#define scm_tc16_pipe 		(scm_tc7_port + 1*256L)

#define scm_tc16_strport	(scm_tc7_port + 2*256L)
#define scm_tc16_sfport 	(scm_tc7_port + 3*256L)


/* There are 256 smob subtypes.  Here are the first four.
 */

#define scm_tc7_smob		127 /* DO NOT CHANGE [**] */

/* [**] If you change scm_tc7_smob, you must also change
 * the places it is hard coded in this file and possibly others.
 */


/* scm_tc_free_cell is also the 0th smob type.
 */
#define scm_tc_free_cell	127

/* The 1st smob type:
 */
#define scm_tc16_flo		0x017f
#define scm_tc_flo		0x017fL

/* Some option bits begeinning at bit 16 of scm_tc16_flo:
 */
#define SCM_REAL_PART		(1L<<16)
#define SCM_IMAG_PART		(2L<<16)
#define scm_tc_dblr		(scm_tc16_flo|SCM_REAL_PART)
#define scm_tc_dblc		(scm_tc16_flo|SCM_REAL_PART|SCM_IMAG_PART)


/* Smob types 2 and 3:
 */
#define scm_tc16_bigpos		0x027f
#define scm_tc16_bigneg		0x037f



/* {Immediate Values}
 */

enum scm_tags
{
  scm_tc8_char = 0xf4,
  scm_tc8_iloc = 0xfc
};

#define SCM_ITAG8(X)		((int)(X) & 0xff)
#define SCM_MAKE_ITAG8(X, TAG)	(((X)<<8) + TAG)
#define SCM_ITAG8_DATA(X)	((X)>>8)



/* Immediate Symbols, Special Symbols, Flags (various constants).
 */

/* SCM_ISYMP tests for ISPCSYM and ISYM */
#define SCM_ISYMP(n) 		((0x187 & (int)(n))==4)

/* SCM_IFLAGP tests for ISPCSYM, ISYM and IFLAG */
#define SCM_IFLAGP(n) 		((0x87 & (int)(n))==4)
#define SCM_ISYMNUM(n) 		((int)((n)>>9))
#define SCM_ISYMCHARS(n) 	(scm_isymnames[SCM_ISYMNUM(n)])
#define SCM_MAKSPCSYM(n) 	(((n)<<9)+((n)<<3)+4L)
#define SCM_MAKISYM(n) 		(((n)<<9)+0x74L)
#define SCM_MAKIFLAG(n) 	(((n)<<9)+0x174L)

/* This table must agree with the declarations
 * in repl.c: {Names of immediate symbols}.
 *
 * These are used only in eval but their values
 * have to be allocated here.
 *
 */

#define SCM_IM_AND		SCM_MAKSPCSYM(0)
#define SCM_IM_BEGIN		SCM_MAKSPCSYM(1)
#define SCM_IM_CASE		SCM_MAKSPCSYM(2)
#define SCM_IM_COND		SCM_MAKSPCSYM(3)
#define SCM_IM_DO		SCM_MAKSPCSYM(4)
#define SCM_IM_IF		SCM_MAKSPCSYM(5)
#define SCM_IM_LAMBDA		SCM_MAKSPCSYM(6)
#define SCM_IM_LET		SCM_MAKSPCSYM(7)
#define SCM_IM_LETSTAR		SCM_MAKSPCSYM(8)
#define SCM_IM_LETREC		SCM_MAKSPCSYM(9)
#define SCM_IM_OR		SCM_MAKSPCSYM(10)
#define SCM_IM_QUOTE		SCM_MAKSPCSYM(11)
#define SCM_IM_SET		SCM_MAKSPCSYM(12)
#define SCM_IM_DEFINE		SCM_MAKSPCSYM(13)
#define SCM_IM_APPLY		SCM_MAKISYM(14)
#define SCM_IM_CONT		SCM_MAKISYM(15)
#define SCM_BOOL_F		SCM_MAKIFLAG(16)
#define SCM_BOOL_T 		SCM_MAKIFLAG(17)
#define SCM_UNDEFINED	 	SCM_MAKIFLAG(18)
#define SCM_EOF_VAL 		SCM_MAKIFLAG(19)
#define SCM_EOL			SCM_MAKIFLAG(20)
#define SCM_UNSPECIFIED		SCM_MAKIFLAG(21)


#define SCM_UNBNDP(x) 	(SCM_UNDEFINED==(x))



/* Dispatching aids:
 */


/* For cons pairs with immediate values in the CAR
 */

#define scm_tcs_cons_imcar 2:case 4:case 6:case 10:\
 case 12:case 14:case 18:case 20:\
 case 22:case 26:case 28:case 30:\
 case 34:case 36:case 38:case 42:\
 case 44:case 46:case 50:case 52:\
 case 54:case 58:case 60:case 62:\
 case 66:case 68:case 70:case 74:\
 case 76:case 78:case 82:case 84:\
 case 86:case 90:case 92:case 94:\
 case 98:case 100:case 102:case 106:\
 case 108:case 110:case 114:case 116:\
 case 118:case 122:case 124:case 126

/* For cons pairs with non-immediate values in the SCM_CAR
 */
#define scm_tcs_cons_nimcar 0:case 8:case 16:case 24:\
 case 32:case 40:case 48:case 56:\
 case 64:case 72:case 80:case 88:\
 case 96:case 104:case 112:case 120

/* A CONS_GLOC occurs in code.  It's CAR is a pointer to the
 * CDR of a variable.  The low order bits of the CAR are 001.
 * The CDR of the gloc is the code continuation.
 */
#define scm_tcs_cons_gloc 1:case 9:case 17:case 25:\
 case 33:case 41:case 49:case 57:\
 case 65:case 73:case 81:case 89:\
 case 97:case 105:case 113:case 121

#define scm_tcs_closures   3:case 11:case 19:case 27:\
 case 35:case 43:case 51:case 59:\
 case 67:case 75:case 83:case 91:\
 case 99:case 107:case 115:case 123

#define scm_tcs_subrs scm_tc7_asubr:case scm_tc7_subr_0:case scm_tc7_subr_1:case scm_tc7_cxr:\
 case scm_tc7_subr_3:case scm_tc7_subr_2:case scm_tc7_rpsubr:case scm_tc7_subr_1o:\
 case scm_tc7_subr_2o:case scm_tc7_lsubr_2:case scm_tc7_lsubr

#define scm_tcs_symbols scm_tc7_ssymbol:case scm_tc7_msymbol

#define scm_tcs_bignums scm_tc16_bigpos:case scm_tc16_bigneg

#endif  /* TAGSH */
