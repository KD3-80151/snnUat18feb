public class NumberToWordsHelper {

    public string wordText { get; set; }
    public Integer numberVal { get; set; }

    public void convert() {
        wordText = numberToEnglish(numberVal);
    }

    static String[] firstTwenty = new String[] { 'NIL','One','Two','Three','Four','Five','Six','Seven','Eight','Nine',
            'Ten','Eleven','Twelve','Thirteen','Fourteen','Fifteen','Sixteen','Seventeen','Eighteen','Nineteen' };
    static String[] tens = new String[] { '','', 'Twenty','Thirty','Forty','Fifty','Sixty','Seventy','Eighty','Ninety' };
    static String[] powers = new String[] { 'Crore','Lakh','Thousand','Hundred' };
    static Integer[] thresholds = new Integer[] { 10000000, 100000, 1000, 100 };

    static String[] convert(Integer value) {
        String[] result = new String[0];
        
        if (value == 0) {
            result.add('Zero');
            return result;
        }

        Boolean less20 = value < 20;
        Boolean less100 = value < 100;
        if(less20) {
            result.add(firstTwenty[value]);
        } else if(less100) {
            Integer tenValue = value / 10;
            Integer oneValue = Math.mod(value, 10);
            result.add(tens[tenValue]);
            if(oneValue > 0) {
                result.add(firstTwenty[oneValue]);
            }
        }
        
        if(less100) {
            return result;
        }
        
        if(value > 0) {
            for(Integer index = 0; index < thresholds.size(); index++) {
                if(value >= thresholds[index]) {
                    Integer quotient = value / thresholds[index];
                    if(quotient > 0) {
                        result.addAll(convert(quotient));
                        result.add(powers[index]);
                        value = Math.mod(value, thresholds[index]);
                    }
                }
            }
        }
        
        if(value > 0) {
            result.addAll(convert(value)); 
        }
        
        return result;
    }

    public static String numberToEnglish(Integer value) {
        return value != null && value >= 0 ? String.join(convert(value),' ') : '';
    }

    // public static String convertAmountToWords(Decimal amount) {
    //     final String[] THOUSANDS  = new String[]{'', 'Thousand', 'Million', 'Billion'};
    //     if (amount == null) return 'Zero Rupees';
        
    //     Long num = amount.longValue(); 
    //     if (num == 0) return 'Zero Rupees';

    //     String result = '';
    //     Integer index = 0;
        
    //     while (num > 0) {
    //         if (Math.mod(num, 1000) != 0) {  
    //             result = convertThreeDigits(Integer.valueOf(Math.mod(num, 1000))) + ' ' + THOUSANDS[index] + ' ' + result;
    //         }
    //         num = num / 1000;  
    //         index++;
    //     }
        
    //     return result.trim() + ' Rupees';
    // }

    // public static String convertThreeDigits(Integer num) {

    //      final String[] ONES = new String[]{'', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
    //                                       'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
    //                                       'Seventeen', 'Eighteen', 'Nineteen'};
    //     final String[] TENS = new String[]{'', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'};
    //     final String[] THOUSANDS = new String[]{'', 'Thousand', 'Million', 'Billion'};


    //     if (num == 0) return '';
    //     else if (num < 20) return ONES[num];
    //     else if (num < 100) return TENS[num / 10] + (Math.mod(num, 10) != 0 ? ' ' + ONES[Math.mod(num, 10)] : '');
    //     else return ONES[num / 100] + ' Hundred' + (Math.mod(num, 100) != 0 ? ' ' + convertThreeDigits(Math.mod(num, 100)) : '');
    // }
}