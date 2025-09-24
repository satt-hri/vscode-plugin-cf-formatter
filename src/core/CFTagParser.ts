class CFTagParser {
	private pos: number = 0;
	private input: string = "";
	private tags: Record<string, any>[] = [];
	constructor() {
		this.reset();
	}

	reset() {
		this.pos = 0;
		this.input = "";
		this.tags = [];
	}

	parse(input: string) {
		this.input = input;
		this.pos = 0;
		this.tags = [];

		while (this.pos < this.input.length) {
			const tagStart = this.input.indexOf("<", this.pos);
			if (tagStart === -1) break;

			this.pos = tagStart;
			const tag = this.parseTag();
			if (tag) {
				this.tags.push(tag);
			} else {
				this.pos++;
			}
		}

		return this.tags;
	}

	parseTag() {
		if (this.pos >= this.input.length || this.input[this.pos] !== "<") {
			return null;
		}

		const start = this.pos;
		this.pos++; // 跳过 <

		// 跳过空白
		this.skipWhitespace();

		// 检查是否是结束标签
		const isClosing = this.peek() === "/";
		if (isClosing) {
			this.pos++;
			this.skipWhitespace();
		}

		// 检查是否是cf标签
		const tagNameMatch = this.input.substring(this.pos).match(/^(cf\w+)/i);
		if (!tagNameMatch) {
			this.pos = start + 1;
			return null;
		}

		const tagName = tagNameMatch[1];
		this.pos += tagName.length;

		// 解析属性
		const attributes = this.parseAttributes();
		if (attributes === null) {
			// 解析失败，可能不是有效标签
			this.pos = start + 1;
			return null;
		}

		// 检查自闭合
		this.skipWhitespace();
		const isSelfClosing = this.peek() === "/" && this.peek(1) === ">";
		if (isSelfClosing) {
			this.pos += 2;
		} else if (this.peek() === ">") {
			this.pos++;
		} else {
			// 无效标签
			this.pos = start + 1;
			return null;
		}

		const end = this.pos;

		return {
			fullMatch: this.input.substring(start, end),
			isClosing,
			tagName: tagName.toLowerCase(),
			attributes: attributes.trim(),
			isSelfClosing,
			start,
			end,
		};
	}

	parseAttributes() {
		let attributes = "";

		while (this.pos < this.input.length) {
			this.skipWhitespace();

			const char = this.peek();

			if (char === ">" || (char === "/" && this.peek(1) === ">")) {
				// 标签结束
				break;
			} else if (char === '"') {
				// 双引号字符串
				const str = this.parseString('"');
				if (str === null) return null;
				attributes += str;
			} else if (char === "'") {
				// 单引号字符串
				const str = this.parseString("'");
				if (str === null) return null;
				attributes += str;
			} else if (char === "<") {
				// 遇到新的标签开始，当前标签可能无效
				return null;
			} else {
				// 普通字符
				attributes += char;
				this.pos++;
			}
		}

		return attributes;
	}

	parseString(quote: string) {
		if (this.peek() !== quote) return null;

		let result = quote;
		this.pos++; // 跳过开始引号

		while (this.pos < this.input.length) {
			const char = this.peek();

			if (char === quote) {
				result += char;
				this.pos++;
				return result;
			} else if (char === "\\") {
				// 处理转义字符
				result += char;
				this.pos++;
				if (this.pos < this.input.length) {
					result += this.peek();
					this.pos++;
				}
			} else {
				result += char;
				this.pos++;
			}
		}

		// 未闭合的字符串
		return null;
	}

	skipWhitespace() {
		while (this.pos < this.input.length && /\s/.test(this.input[this.pos])) {
			this.pos++;
		}
	}

	peek(offset = 0) {
		const pos = this.pos + offset;
		return pos < this.input.length ? this.input[pos] : "";
	}
}
