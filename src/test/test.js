// const mainKeywords = ["SELECT", "INSERT", "UPDATE", "DELETE", "WITH"];
// const text1 = "update_"
// mainKeywords.some(keyword => {
//     const re = new RegExp(`^${keyword}(?=\\s*)`, 'i');
//     const re1 = new RegExp(`^${keyword}(?=\\s|$)`, 'i');
//     //const ret = `/^${keyword}(?=(\s|_))/i`;
//     console.log(keyword, re.test(text1), re1.test(text1));
// })


				// const mainnKeywordsRegex = /^(SELECT|INSERT|UPDATE|DELETE|WITH)(?=\s|$)/i; 
				// if (mainnKeywordsRegex.test(upperText)) {
				// 	return baseIndent;
				// }
let upperText ="authentication_key"
const mainKeywords = ["SELECT", "INSERT", "UPDATE", "DELETE", "WITH"];
if (
    mainKeywords.some((keyword) => {
        const reg = new RegExp(`^${keyword}(?=\\s|$)`, "i");
        return reg.test(upperText);
    })
) {
    return baseIndent; // SQL 主要关键词保持基础缩进
}