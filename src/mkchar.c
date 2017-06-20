/*
 * Copyright 2017 Patrick O. Perry.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <limits.h>
#include "corpus/src/error.h"
#include "corpus/src/text.h"
#include "corpus/src/unicode.h"
#include "rcorpus.h"


static void mkchar_ensure(struct mkchar *mk, int nmin);


void mkchar_init(struct mkchar *mk)
{
	mk->buf = NULL;
	mk->size = 0;
}


SEXP mkchar_get(struct mkchar *mk, const struct corpus_text *text)
{
	SEXP ans;
	uint8_t *ptr;
	size_t len = CORPUS_TEXT_SIZE(text);
	struct corpus_text_iter it;

	if (len >= INT_MAX) {
		error("character string length exceeds maximum (%d)",
			INT_MAX - 1);
	}

	if (text->ptr == NULL) {
		ans = NA_STRING;
	} else {
		if (CORPUS_TEXT_HAS_ESC(text)) {
			mkchar_ensure(mk, (int)len);

			corpus_text_iter_make(&it, text);
			ptr = mk->buf;
			while (corpus_text_iter_advance(&it)) {
				corpus_encode_utf8(it.current, &ptr);
			}
			len = (size_t)(ptr - mk->buf);
			ptr = mk->buf;
		} else {
			ptr = (uint8_t *)text->ptr;
		}

		ans = mkCharLenCE((char *)ptr, (int)len, CE_UTF8);
	}

	return ans;
}


static void mkchar_ensure(struct mkchar *mk, int nmin)
{
	double n1;
	int size = mk->size;

	if (nmin <= size) {
		return;
	}

	// determine the new size
	n1 = size ? (double)size : 32; // minimum size: 32
	while (n1 < nmin) {
		n1 *= 1.618; // golden ratio
	}

	if (n1 > (double)INT_MAX) {
		size = INT_MAX;
	} else {
		size = (int)n1;
	}

	mk->buf = (void *)R_alloc(size, sizeof(uint8_t));
	mk->size = size;
}
