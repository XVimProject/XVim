//
//  XVimStringBuffer.h
//  XVim
//
//  Created by John AppleSeed on 16/11/13.
//
//

#import <Foundation/Foundation.h>

#define XVIM_STRING_BUFFER_SIZE  64

/** @brief structure used for fast search in an NSString
 *
 * This has complex invariants:
 * - b_index is always > 0 unless at the beginning of the allowed range
 * - if b_len < sizeof(buffer) buffer[b_len] is XVimInvalidChar
 *
 * Those allow peek_next() and peek_prev() to be fast and well defined
 *
 * Thisis a c-ish interface, so following Apple recent trend,
 * APIs are in small caps.
 */
typedef struct xvim_string_buffer_s {
    NSString  *__unsafe_unretained s;
    NSUInteger s_min;    // min index within s to clip enumeration to
    NSUInteger s_max;    // max index within s to clip enumeration to
    NSUInteger s_index;  // index of buffer[0] in s
    NSUInteger b_index;  // index in buffer being read
    NSUInteger b_len;    // number of characters read in buffer
    unichar    buffer[XVIM_STRING_BUFFER_SIZE];
} xvim_string_buffer_t;

#define XVimInvalidChar  ((unichar)-1)

NS_INLINE void _xvim_sb_load(xvim_string_buffer_t *sb)
{
    NSUInteger len = MIN(sb->s_max - sb->s_index, XVIM_STRING_BUFFER_SIZE);

    sb->b_len = len;
    NSCAssert(sb->b_len <= XVIM_STRING_BUFFER_SIZE, @"b_len is bogus");
    if (len > 0) {
        [sb->s getCharacters:sb->buffer range:NSMakeRange(sb->s_index, len)];
    }
    if (len < XVIM_STRING_BUFFER_SIZE) {
        sb->buffer[len] = XVimInvalidChar;
    }
}

/* returns NO if at end */
NS_INLINE void xvim_sb_init(xvim_string_buffer_t *sb, NSString *s,
                            NSUInteger index, NSUInteger min, NSUInteger max)
{
    sb->s = s;
    sb->s_min = min;
    sb->s_max = max;

    NSCAssert(min <= max, @"Bad xvim_sb_init");
    NSCAssert(index >= sb->s_min && index <= sb->s_max, @"bad xvim_sb_init");
    NSCAssert(max <= s.length, @"bad xvim_sb_init");

    if (max - min < XVIM_STRING_BUFFER_SIZE || index - XVIM_STRING_BUFFER_SIZE / 2 < sb->s_min) {
        sb->s_index = sb->s_min;
    } else if (index + XVIM_STRING_BUFFER_SIZE >= sb->s_max) {
        sb->s_index = sb->s_max - XVIM_STRING_BUFFER_SIZE + 1;
    } else {
        sb->s_index = index - XVIM_STRING_BUFFER_SIZE / 2;
    }
    sb->b_index = index - sb->s_index;
    _xvim_sb_load(sb);
}

NS_INLINE void xvim_sb_init_range(xvim_string_buffer_t *sb, NSString *s, NSRange range)
{
    xvim_sb_init(sb, s, range.location, range.location, NSMaxRange(range));
}

NS_INLINE NSUInteger xvim_sb_index(xvim_string_buffer_t *sb)
{
    return sb->s_index + sb->b_index;
}

NS_INLINE NSRange xvim_sb_range_to_start(xvim_string_buffer_t *sb)
{
    return NSMakeRange(sb->s_min, xvim_sb_index(sb) - sb->s_min);
}

NS_INLINE NSRange xvim_sb_range_to_end(xvim_string_buffer_t *sb)
{
    return NSMakeRange(xvim_sb_index(sb), sb->s_max - xvim_sb_index(sb));
}

NS_INLINE unichar xvim_sb_peek_prev(xvim_string_buffer_t *sb)
{
    return sb->b_index == 0 ? XVimInvalidChar : sb->buffer[sb->b_index - 1];
}

NS_INLINE unichar xvim_sb_peek(xvim_string_buffer_t *sb)
{
    return sb->buffer[sb->b_index];
}

NS_INLINE BOOL xvim_sb_at_start(xvim_string_buffer_t *sb)
{
    return sb->b_index == 0;
}

NS_INLINE BOOL xvim_sb_at_end(xvim_string_buffer_t *sb)
{
    return xvim_sb_peek(sb) == XVimInvalidChar;
}

/* returns NO when at end of string */
NS_INLINE BOOL xvim_sb_next(xvim_string_buffer_t *sb)
{
    if (xvim_sb_at_end(sb)) {
        return NO;
    }
    sb->b_index++;
    if (sb->b_index < sb->b_len) {
        return YES;
    }
    if (sb->b_len < XVIM_STRING_BUFFER_SIZE) {
        return NO;
    }
    sb->s_index += XVIM_STRING_BUFFER_SIZE / 2;
    sb->b_index  = XVIM_STRING_BUFFER_SIZE / 2;
    _xvim_sb_load(sb);
    return sb->b_index < sb->b_len;
}

/* returns NO when at beggining of string */
NS_INLINE BOOL xvim_sb_prev(xvim_string_buffer_t *sb)
{
    if (sb->b_index > 1) {
        sb->b_index--;
        return YES;
    }

    NSUInteger diff = MIN(sb->s_index - sb->s_min, XVIM_STRING_BUFFER_SIZE / 2);
    if (diff > 0) {
        sb->s_index -= diff;
        sb->b_index  = diff;
        _xvim_sb_load(sb);
        return YES;
    }

    if (sb->b_index > 0) {
        sb->b_index--;
    }
    return NO;
}

/* skips chars until end of string or peek_next() not in set */
NS_INLINE BOOL xvim_sb_skip_forward(xvim_string_buffer_t *sb, NSCharacterSet *set)
{
    if (!xvim_sb_at_end(sb)) {
        do {
            if (![set characterIsMember:xvim_sb_peek(sb)]) {
                return YES;
            }
        } while (xvim_sb_next(sb));
    }

    return NO;
}

/* skips chars until end of string or peek_next() in set */
NS_INLINE BOOL xvim_sb_find_forward(xvim_string_buffer_t *sb, NSCharacterSet *set)
{
    if (!xvim_sb_at_end(sb)) {
        do {
            if ([set characterIsMember:xvim_sb_peek(sb)]) {
                return YES;
            }
        } while (xvim_sb_next(sb));
    }

    return NO;
}

/* go back until start of string or peek_prev() not in set */
NS_INLINE BOOL xvim_sb_skip_backward(xvim_string_buffer_t *sb, NSCharacterSet *set)
{
    if (!xvim_sb_at_start(sb)) {
        do {
            if (![set characterIsMember:xvim_sb_peek_prev(sb)]) {
                return YES;
            }
        } while (xvim_sb_prev(sb));
    }

    return NO;
}

/* go back until start of string or peek_prev() not in set */
NS_INLINE BOOL xvim_sb_find_backward(xvim_string_buffer_t *sb, NSCharacterSet *set)
{
    if (!xvim_sb_at_start(sb)) {
        do {
            if ([set characterIsMember:xvim_sb_peek_prev(sb)]) {
                return YES;
            }
        } while (xvim_sb_prev(sb));
    }

    return NO;
}
