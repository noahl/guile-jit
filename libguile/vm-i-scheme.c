/* Copyright (C) 2001, 2009 Free Software Foundation, Inc.
 * 
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public License
 * as published by the Free Software Foundation; either version 3 of
 * the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA
 * 02110-1301 USA
 */

/* This file is included in vm_engine.c */


/*
 * Predicates
 */

#define ARGS1(a1)	SCM a1 = sp[0];
#define ARGS2(a1,a2)	SCM a1 = sp[-1], a2 = sp[0]; sp--; NULLSTACK (1);
#define ARGS3(a1,a2,a3)	SCM a1 = sp[-2], a2 = sp[-1], a3 = sp[0]; sp -= 2; NULLSTACK (2);

#define RETURN(x)	do { *sp = x; NEXT; } while (0)

VM_DEFINE_FUNCTION (100, not, "not", 1)
{
  ARGS1 (x);
  RETURN (SCM_BOOL (scm_is_false_or_nil (x)));
}

VM_DEFINE_FUNCTION (101, not_not, "not-not", 1)
{
  ARGS1 (x);
  RETURN (SCM_BOOL (!scm_is_false_or_nil (x)));
}

VM_DEFINE_FUNCTION (102, eq, "eq?", 2)
{
  ARGS2 (x, y);
  RETURN (SCM_BOOL (SCM_EQ_P (x, y)));
}

VM_DEFINE_FUNCTION (103, not_eq, "not-eq?", 2)
{
  ARGS2 (x, y);
  RETURN (SCM_BOOL (!SCM_EQ_P (x, y)));
}

VM_DEFINE_FUNCTION (104, nullp, "null?", 1)
{
  ARGS1 (x);
  RETURN (SCM_BOOL (scm_is_null_or_nil (x)));
}

VM_DEFINE_FUNCTION (105, not_nullp, "not-null?", 1)
{
  ARGS1 (x);
  RETURN (SCM_BOOL (!scm_is_null_or_nil (x)));
}

VM_DEFINE_FUNCTION (106, eqv, "eqv?", 2)
{
  ARGS2 (x, y);
  if (SCM_EQ_P (x, y))
    RETURN (SCM_BOOL_T);
  if (SCM_IMP (x) || SCM_IMP (y))
    RETURN (SCM_BOOL_F);
  SYNC_REGISTER ();
  RETURN (scm_eqv_p (x, y));
}

VM_DEFINE_FUNCTION (107, equal, "equal?", 2)
{
  ARGS2 (x, y);
  if (SCM_EQ_P (x, y))
    RETURN (SCM_BOOL_T);
  if (SCM_IMP (x) || SCM_IMP (y))
    RETURN (SCM_BOOL_F);
  SYNC_REGISTER ();
  RETURN (scm_equal_p (x, y));
}

VM_DEFINE_FUNCTION (108, pairp, "pair?", 1)
{
  ARGS1 (x);
  RETURN (SCM_BOOL (SCM_CONSP (x)));
}

VM_DEFINE_FUNCTION (109, listp, "list?", 1)
{
  ARGS1 (x);
  RETURN (SCM_BOOL (scm_ilength (x) >= 0));
}


/*
 * Basic data
 */

VM_DEFINE_FUNCTION (110, cons, "cons", 2)
{
  ARGS2 (x, y);
  CONS (x, x, y);
  RETURN (x);
}

#define VM_VALIDATE_CONS(x)                     \
  if (SCM_UNLIKELY (!scm_is_pair (x)))          \
    { finish_args = x;                          \
      goto vm_error_not_a_pair;                 \
    }
  
VM_DEFINE_FUNCTION (111, car, "car", 1)
{
  ARGS1 (x);
  VM_VALIDATE_CONS (x);
  RETURN (SCM_CAR (x));
}

VM_DEFINE_FUNCTION (112, cdr, "cdr", 1)
{
  ARGS1 (x);
  VM_VALIDATE_CONS (x);
  RETURN (SCM_CDR (x));
}

VM_DEFINE_INSTRUCTION (113, set_car, "set-car!", 0, 2, 0)
{
  SCM x, y;
  POP (y);
  POP (x);
  VM_VALIDATE_CONS (x);
  SCM_SETCAR (x, y);
  NEXT;
}

VM_DEFINE_INSTRUCTION (114, set_cdr, "set-cdr!", 0, 2, 0)
{
  SCM x, y;
  POP (y);
  POP (x);
  VM_VALIDATE_CONS (x);
  SCM_SETCDR (x, y);
  NEXT;
}


/*
 * Numeric relational tests
 */

#undef REL
#define REL(crel,srel)						\
{								\
  ARGS2 (x, y);							\
  if (SCM_I_INUMP (x) && SCM_I_INUMP (y))			\
    RETURN (SCM_BOOL (SCM_I_INUM (x) crel SCM_I_INUM (y)));	\
  SYNC_REGISTER ();                                             \
  RETURN (srel (x, y));                                         \
}

VM_DEFINE_FUNCTION (115, ee, "ee?", 2)
{
  REL (==, scm_num_eq_p);
}

VM_DEFINE_FUNCTION (116, lt, "lt?", 2)
{
  REL (<, scm_less_p);
}

VM_DEFINE_FUNCTION (117, le, "le?", 2)
{
  REL (<=, scm_leq_p);
}

VM_DEFINE_FUNCTION (118, gt, "gt?", 2)
{
  REL (>, scm_gr_p);
}

VM_DEFINE_FUNCTION (119, ge, "ge?", 2)
{
  REL (>=, scm_geq_p);
}


/*
 * Numeric functions
 */

#undef FUNC2
#define FUNC2(CFUNC,SFUNC)				\
{							\
  ARGS2 (x, y);						\
  if (SCM_I_INUMP (x) && SCM_I_INUMP (y))		\
    {							\
      scm_t_int64 n = SCM_I_INUM (x) CFUNC SCM_I_INUM (y);\
      if (SCM_FIXABLE (n))				\
	RETURN (SCM_I_MAKINUM (n));			\
    }							\
  SYNC_REGISTER ();					\
  RETURN (SFUNC (x, y));				\
}

VM_DEFINE_FUNCTION (120, add, "add", 2)
{
  FUNC2 (+, scm_sum);
}

VM_DEFINE_FUNCTION (167, add1, "add1", 1)
{
  ARGS1 (x);
  if (SCM_I_INUMP (x))
    {
      scm_t_int64 n = SCM_I_INUM (x) + 1;
      if (SCM_FIXABLE (n))
	RETURN (SCM_I_MAKINUM (n));
    }
  SYNC_REGISTER ();
  RETURN (scm_sum (x, SCM_I_MAKINUM (1)));
}

VM_DEFINE_FUNCTION (121, sub, "sub", 2)
{
  FUNC2 (-, scm_difference);
}

VM_DEFINE_FUNCTION (168, sub1, "sub1", 1)
{
  ARGS1 (x);
  if (SCM_I_INUMP (x))
    {
      scm_t_int64 n = SCM_I_INUM (x) - 1;
      if (SCM_FIXABLE (n))
	RETURN (SCM_I_MAKINUM (n));
    }
  SYNC_REGISTER ();
  RETURN (scm_difference (x, SCM_I_MAKINUM (1)));
}

VM_DEFINE_FUNCTION (122, mul, "mul", 2)
{
  ARGS2 (x, y);
  SYNC_REGISTER ();
  RETURN (scm_product (x, y));
}

VM_DEFINE_FUNCTION (123, div, "div", 2)
{
  ARGS2 (x, y);
  SYNC_REGISTER ();
  RETURN (scm_divide (x, y));
}

VM_DEFINE_FUNCTION (124, quo, "quo", 2)
{
  ARGS2 (x, y);
  SYNC_REGISTER ();
  RETURN (scm_quotient (x, y));
}

VM_DEFINE_FUNCTION (125, rem, "rem", 2)
{
  ARGS2 (x, y);
  SYNC_REGISTER ();
  RETURN (scm_remainder (x, y));
}

VM_DEFINE_FUNCTION (126, mod, "mod", 2)
{
  ARGS2 (x, y);
  SYNC_REGISTER ();
  RETURN (scm_modulo (x, y));
}


/*
 * GOOPS support
 */
VM_DEFINE_FUNCTION (169, class_of, "class-of", 1)
{
  ARGS1 (obj);
  RETURN (SCM_INSTANCEP (obj) ? SCM_CLASS_OF (obj) : scm_class_of (obj));
}

VM_DEFINE_FUNCTION (127, slot_ref, "slot-ref", 2)
{
  size_t slot;
  ARGS2 (instance, idx);
  slot = SCM_I_INUM (idx);
  RETURN (SCM_PACK (SCM_STRUCT_DATA (instance) [slot]));
}

VM_DEFINE_INSTRUCTION (128, slot_set, "slot-set", 0, 3, 0)
{
  SCM instance, idx, val;
  size_t slot;
  POP (val);
  POP (idx);
  POP (instance);
  slot = SCM_I_INUM (idx);
  SCM_STRUCT_DATA (instance) [slot] = SCM_UNPACK (val);
  NEXT;
}

VM_DEFINE_FUNCTION (129, vector_ref, "vector-ref", 2)
{
  long i = 0;
  ARGS2 (vect, idx);
  if (SCM_LIKELY (SCM_I_IS_VECTOR (vect)
                  && SCM_I_INUMP (idx)
                  && ((i = SCM_I_INUM (idx)) >= 0)
                  && i < SCM_I_VECTOR_LENGTH (vect)))
    RETURN (SCM_I_VECTOR_ELTS (vect)[i]);
  else
    {
      SYNC_REGISTER ();
      RETURN (scm_vector_ref (vect, idx));
    }
}

VM_DEFINE_INSTRUCTION (130, vector_set, "vector-set", 0, 3, 0)
{
  long i = 0;
  SCM vect, idx, val;
  POP (val); POP (idx); POP (vect);
  if (SCM_LIKELY (SCM_I_IS_VECTOR (vect)
                  && SCM_I_INUMP (idx)
                  && ((i = SCM_I_INUM (idx)) >= 0)
                  && i < SCM_I_VECTOR_LENGTH (vect)))
    SCM_I_VECTOR_WELTS (vect)[i] = val;
  else
    {
      SYNC_REGISTER ();
      scm_vector_set_x (vect, idx, val);
    }
  NEXT;
}

#define VM_VALIDATE_BYTEVECTOR(x)               \
  if (SCM_UNLIKELY (!SCM_BYTEVECTOR_P (x)))     \
    { finish_args = x;                          \
      goto vm_error_not_a_bytevector;           \
    }

#define BV_REF_WITH_ENDIANNESS(stem, fn_stem)                           \
{                                                                       \
  SCM endianness;                                                       \
  POP (endianness);                                                     \
  if (scm_is_eq (endianness, scm_i_native_endianness))                  \
    goto VM_LABEL (bv_##stem##_native_ref);                             \
  {                                                                     \
    ARGS2 (bv, idx);                                                    \
    RETURN (scm_bytevector_##fn_stem##_ref (bv, idx, endianness));      \
  }                                                                     \
}

VM_DEFINE_FUNCTION (131, bv_u16_ref, "bv-u16-ref", 3)
BV_REF_WITH_ENDIANNESS (u16, u16)
VM_DEFINE_FUNCTION (132, bv_s16_ref, "bv-s16-ref", 3)
BV_REF_WITH_ENDIANNESS (s16, s16)
VM_DEFINE_FUNCTION (133, bv_u32_ref, "bv-u32-ref", 3)
BV_REF_WITH_ENDIANNESS (u32, u32)
VM_DEFINE_FUNCTION (134, bv_s32_ref, "bv-s32-ref", 3)
BV_REF_WITH_ENDIANNESS (s32, s32)
VM_DEFINE_FUNCTION (135, bv_u64_ref, "bv-u64-ref", 3)
BV_REF_WITH_ENDIANNESS (u64, u64)
VM_DEFINE_FUNCTION (136, bv_s64_ref, "bv-s64-ref", 3)
BV_REF_WITH_ENDIANNESS (s64, s64)
VM_DEFINE_FUNCTION (137, bv_f32_ref, "bv-f32-ref", 3)
BV_REF_WITH_ENDIANNESS (f32, ieee_single)
VM_DEFINE_FUNCTION (138, bv_f64_ref, "bv-f64-ref", 3)
BV_REF_WITH_ENDIANNESS (f64, ieee_double)

#undef BV_REF_WITH_ENDIANNESS

#define BV_FIXABLE_INT_REF(stem, fn_stem, type, size)                   \
{                                                                       \
  long i = 0;                                                           \
  ARGS2 (bv, idx);                                                      \
  VM_VALIDATE_BYTEVECTOR (bv);                                          \
  if (SCM_LIKELY (SCM_I_INUMP (idx)                                     \
                  && ((i = SCM_I_INUM (idx)) >= 0)                        \
                  && (i + size <= SCM_BYTEVECTOR_LENGTH (bv))           \
                  && (i % size == 0)))                                  \
    RETURN (SCM_I_MAKINUM (*(scm_t_##type*)                             \
                           (SCM_BYTEVECTOR_CONTENTS (bv) + i)));        \
  else                                                                  \
    RETURN (scm_bytevector_##fn_stem##_ref (bv, idx));                  \
}

#define BV_INT_REF(stem, type, size)                                    \
{                                                                       \
  long i = 0;                                                           \
  ARGS2 (bv, idx);                                                      \
  VM_VALIDATE_BYTEVECTOR (bv);                                          \
  if (SCM_LIKELY (SCM_I_INUMP (idx)                                     \
                  && ((i = SCM_I_INUM (idx)) >= 0)                      \
                  && (i + size <= SCM_BYTEVECTOR_LENGTH (bv))           \
                  && (i % size == 0)))                                  \
    { scm_t_##type x = (*(scm_t_##type*)(SCM_BYTEVECTOR_CONTENTS (bv) + i)); \
      if (SCM_FIXABLE (x))                                              \
        RETURN (SCM_I_MAKINUM (x));                                     \
      else                                                              \
        RETURN (scm_from_##type (x));                                   \
    }                                                                   \
  else                                                                  \
    RETURN (scm_bytevector_##stem##_native_ref (bv, idx));              \
}

#define BV_FLOAT_REF(stem, fn_stem, type, size)                         \
{                                                                       \
  long i = 0;                                                           \
  ARGS2 (bv, idx);                                                      \
  VM_VALIDATE_BYTEVECTOR (bv);                                          \
  if (SCM_LIKELY (SCM_I_INUMP (idx)                                     \
                  && ((i = SCM_I_INUM (idx)) >= 0)                        \
                  && (i + size <= SCM_BYTEVECTOR_LENGTH (bv))           \
                  && (i % size == 0)))                                  \
    RETURN (scm_from_double ((*(type*)(SCM_BYTEVECTOR_CONTENTS (bv) + i)))); \
  else                                                                  \
    RETURN (scm_bytevector_##fn_stem##_native_ref (bv, idx));           \
}

VM_DEFINE_FUNCTION (139, bv_u8_ref, "bv-u8-ref", 2)
BV_FIXABLE_INT_REF (u8, u8, uint8, 1)
VM_DEFINE_FUNCTION (140, bv_s8_ref, "bv-s8-ref", 2)
BV_FIXABLE_INT_REF (s8, s8, int8, 1)
VM_DEFINE_FUNCTION (141, bv_u16_native_ref, "bv-u16-native-ref", 2)
BV_FIXABLE_INT_REF (u16, u16_native, uint16, 2)
VM_DEFINE_FUNCTION (142, bv_s16_native_ref, "bv-s16-native-ref", 2)
BV_FIXABLE_INT_REF (s16, s16_native, int16, 2)
VM_DEFINE_FUNCTION (143, bv_u32_native_ref, "bv-u32-native-ref", 2)
#if SIZEOF_VOID_P > 4
BV_FIXABLE_INT_REF (u32, u32_native, uint32, 4)
#else
BV_INT_REF (u32, uint32, 4)
#endif
VM_DEFINE_FUNCTION (144, bv_s32_native_ref, "bv-s32-native-ref", 2)
#if SIZEOF_VOID_P > 4
BV_FIXABLE_INT_REF (s32, s32_native, int32, 4)
#else
BV_INT_REF (s32, int32, 4)
#endif
VM_DEFINE_FUNCTION (145, bv_u64_native_ref, "bv-u64-native-ref", 2)
BV_INT_REF (u64, uint64, 8)
VM_DEFINE_FUNCTION (146, bv_s64_native_ref, "bv-s64-native-ref", 2)
BV_INT_REF (s64, int64, 8)
VM_DEFINE_FUNCTION (147, bv_f32_native_ref, "bv-f32-native-ref", 2)
BV_FLOAT_REF (f32, ieee_single, float, 4)
VM_DEFINE_FUNCTION (148, bv_f64_native_ref, "bv-f64-native-ref", 2)
BV_FLOAT_REF (f64, ieee_double, double, 8)

#undef BV_FIXABLE_INT_REF
#undef BV_INT_REF
#undef BV_FLOAT_REF



#define BV_SET_WITH_ENDIANNESS(stem, fn_stem)                           \
{                                                                       \
  SCM endianness;                                                       \
  POP (endianness);                                                     \
  if (scm_is_eq (endianness, scm_i_native_endianness))                  \
    goto VM_LABEL (bv_##stem##_native_set);                             \
  {                                                                     \
    SCM bv, idx, val; POP (val); POP (idx); POP (bv);                   \
    scm_bytevector_##fn_stem##_set_x (bv, idx, val, endianness);        \
    NEXT;                                                               \
  }                                                                     \
}

VM_DEFINE_INSTRUCTION (149, bv_u16_set, "bv-u16-set", 0, 4, 0)
BV_SET_WITH_ENDIANNESS (u16, u16)
VM_DEFINE_INSTRUCTION (150, bv_s16_set, "bv-s16-set", 0, 4, 0)
BV_SET_WITH_ENDIANNESS (s16, s16)
VM_DEFINE_INSTRUCTION (151, bv_u32_set, "bv-u32-set", 0, 4, 0)
BV_SET_WITH_ENDIANNESS (u32, u32)
VM_DEFINE_INSTRUCTION (152, bv_s32_set, "bv-s32-set", 0, 4, 0)
BV_SET_WITH_ENDIANNESS (s32, s32)
VM_DEFINE_INSTRUCTION (153, bv_u64_set, "bv-u64-set", 0, 4, 0)
BV_SET_WITH_ENDIANNESS (u64, u64)
VM_DEFINE_INSTRUCTION (154, bv_s64_set, "bv-s64-set", 0, 4, 0)
BV_SET_WITH_ENDIANNESS (s64, s64)
VM_DEFINE_INSTRUCTION (155, bv_f32_set, "bv-f32-set", 0, 4, 0)
BV_SET_WITH_ENDIANNESS (f32, ieee_single)
VM_DEFINE_INSTRUCTION (156, bv_f64_set, "bv-f64-set", 0, 4, 0)
BV_SET_WITH_ENDIANNESS (f64, ieee_double)

#undef BV_SET_WITH_ENDIANNESS

#define BV_FIXABLE_INT_SET(stem, fn_stem, type, min, max, size)         \
{                                                                       \
  long i = 0, j = 0;                                                    \
  SCM bv, idx, val; POP (val); POP (idx); POP (bv);                     \
  VM_VALIDATE_BYTEVECTOR (bv);                                          \
  if (SCM_LIKELY (SCM_I_INUMP (idx)                                     \
                  && ((i = SCM_I_INUM (idx)) >= 0)                      \
                  && (i + size <= SCM_BYTEVECTOR_LENGTH (bv))           \
                  && (i % size == 0)                                    \
                  && (SCM_I_INUMP (val))                                \
                  && ((j = SCM_I_INUM (val)) >= min)                    \
                  && (j <= max)))                                       \
    *(scm_t_##type*) (SCM_BYTEVECTOR_CONTENTS (bv) + i) = (scm_t_##type)j; \
  else                                                                  \
    scm_bytevector_##fn_stem##_set_x (bv, idx, val);                    \
  NEXT;                                                                 \
}

#define BV_INT_SET(stem, type, size)                                    \
{                                                                       \
  long i = 0;                                                           \
  SCM bv, idx, val; POP (val); POP (idx); POP (bv);                     \
  VM_VALIDATE_BYTEVECTOR (bv);                                          \
  if (SCM_LIKELY (SCM_I_INUMP (idx)                                     \
                  && ((i = SCM_I_INUM (idx)) >= 0)                      \
                  && (i + size <= SCM_BYTEVECTOR_LENGTH (bv))           \
                  && (i % size == 0)))                                  \
    *(scm_t_##type*) (SCM_BYTEVECTOR_CONTENTS (bv) + i) = scm_to_##type (val); \
  else                                                                  \
    scm_bytevector_##stem##_native_set_x (bv, idx, val);                \
  NEXT;                                                                 \
}

#define BV_FLOAT_SET(stem, fn_stem, type, size)                         \
{                                                                       \
  long i = 0;                                                           \
  SCM bv, idx, val; POP (val); POP (idx); POP (bv);                     \
  VM_VALIDATE_BYTEVECTOR (bv);                                          \
  if (SCM_LIKELY (SCM_I_INUMP (idx)                                     \
                  && ((i = SCM_I_INUM (idx)) >= 0)                      \
                  && (i + size <= SCM_BYTEVECTOR_LENGTH (bv))           \
                  && (i % size == 0)))                                  \
    *(type*) (SCM_BYTEVECTOR_CONTENTS (bv) + i) = scm_to_double (val);  \
  else                                                                  \
    scm_bytevector_##fn_stem##_native_set_x (bv, idx, val);             \
  NEXT;                                                                 \
}

VM_DEFINE_INSTRUCTION (157, bv_u8_set, "bv-u8-set", 0, 3, 0)
BV_FIXABLE_INT_SET (u8, u8, uint8, 0, SCM_T_UINT8_MAX, 1)
VM_DEFINE_INSTRUCTION (158, bv_s8_set, "bv-s8-set", 0, 3, 0)
BV_FIXABLE_INT_SET (s8, s8, int8, SCM_T_INT8_MIN, SCM_T_INT8_MAX, 1)
VM_DEFINE_INSTRUCTION (159, bv_u16_native_set, "bv-u16-native-set", 0, 3, 0)
BV_FIXABLE_INT_SET (u16, u16_native, uint16, 0, SCM_T_UINT16_MAX, 2)
VM_DEFINE_INSTRUCTION (160, bv_s16_native_set, "bv-s16-native-set", 0, 3, 0)
BV_FIXABLE_INT_SET (s16, s16_native, int16, SCM_T_INT16_MIN, SCM_T_INT16_MAX, 2)
VM_DEFINE_INSTRUCTION (161, bv_u32_native_set, "bv-u32-native-set", 0, 3, 0)
#if SIZEOF_VOID_P > 4
BV_FIXABLE_INT_SET (u32, u32_native, uint32, 0, SCM_T_UINT32_MAX, 4)
#else
BV_INT_SET (u32, uint32, 4)
#endif
VM_DEFINE_INSTRUCTION (162, bv_s32_native_set, "bv-s32-native-set", 0, 3, 0)
#if SIZEOF_VOID_P > 4
BV_FIXABLE_INT_SET (s32, s32_native, int32, SCM_T_INT32_MIN, SCM_T_INT32_MAX, 4)
#else
BV_INT_SET (s32, int32, 4)
#endif
VM_DEFINE_INSTRUCTION (163, bv_u64_native_set, "bv-u64-native-set", 0, 3, 0)
BV_INT_SET (u64, uint64, 8)
VM_DEFINE_INSTRUCTION (164, bv_s64_native_set, "bv-s64-native-set", 0, 3, 0)
BV_INT_SET (s64, int64, 8)
VM_DEFINE_INSTRUCTION (165, bv_f32_native_set, "bv-f32-native-set", 0, 3, 0)
BV_FLOAT_SET (f32, ieee_single, float, 4)
VM_DEFINE_INSTRUCTION (166, bv_f64_native_set, "bv-f64-native-set", 0, 3, 0)
BV_FLOAT_SET (f64, ieee_double, double, 8)

#undef BV_FIXABLE_INT_SET
#undef BV_INT_SET
#undef BV_FLOAT_SET

/*
(defun renumber-ops ()
  "start from top of buffer and renumber 'VM_DEFINE_FOO (\n' sequences"
  (interactive "")
  (save-excursion
    (let ((counter 99)) (goto-char (point-min))
      (while (re-search-forward "^VM_DEFINE_[^ ]+ (\\([^,]+\\)," (point-max) t)
        (replace-match
         (number-to-string (setq counter (1+ counter)))
          t t nil 1)))))
*/

/*
  Local Variables:
  c-file-style: "gnu"
  End:
*/
