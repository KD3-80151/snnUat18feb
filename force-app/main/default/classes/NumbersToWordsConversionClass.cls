public class NumbersToWordsConversionClass {
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
    
    public static String numberToEnglishDecimal(Decimal value) {
    if(value == null || value < 0) return '';
    Integer integerPart = Integer.valueOf(value.setScale(0, RoundingMode.DOWN));
    Decimal decimalPart = value - integerPart;
    Decimal paisaPart = (decimalPart * 100).setScale(0, RoundingMode.DOWN); 
    Integer paisaInteger = Integer.valueOf(paisaPart);
    String words = String.join(convert(integerPart), ' ');
    if(paisaInteger > 0) {
        words += ' and ' + String.join(convert(paisaInteger), ' ') + ' Paisa';
    }
    return words;
    }
    
    public static String formatIndianCurrency(Decimal amount) {
        System.debug('amount--->'+amount);
        Integer roundedAmount = amount.setScale(0, RoundingMode.HALF_UP).intValue();
        String numStr = String.valueOf(Math.abs(roundedAmount));
        Integer len = numStr.length();
        if (len <= 3) {
            return numStr;
        }
        String lastThree = numStr.substring(len - 3);
        String rest = numStr.substring(0, len - 3);
        String result = '';
        Integer i = rest.length();
        while (i > 2) {
            i -= 2;
            result = ',' + rest.substring(i, i + 2) + result;
        }
        if (i > 0) {
            result = rest.substring(0, i) + result;
        }
        system.debug('result--->'+result);
        return result + ',' + lastThree;
    }

     public static String formatIndianCurrencyDecimal(Decimal amount) {
        System.debug('amount--->' + amount);
        if (amount == null) return '';
        Decimal absAmount = Math.abs(amount);
        Integer integerPart = Integer.valueOf(absAmount.setScale(0, RoundingMode.DOWN));
        Decimal decimalPart = absAmount - integerPart;
        String decimalStr = '';
        if (decimalPart != 0) {
            String[] parts = String.valueOf(absAmount).split('\\.');
            if(parts.size() > 1) {
                decimalStr = '.' + parts[1];
            }
        }
        String numStr = String.valueOf(integerPart);
        Integer len = numStr.length();
        if (len <= 3) {
            return numStr + decimalStr;
        }

        String lastThree = numStr.substring(len - 3);
        String rest = numStr.substring(0, len - 3);
        String result = '';
        Integer i = rest.length();
        while (i > 2) {
            i -= 2;
            result = ',' + rest.substring(i, i + 2) + result;
        }
        if (i > 0) {
            result = rest.substring(0, i) + result;
        }
        return result + ',' + lastThree + decimalStr;
    }

    public static String formattedDate(Date dateValue){
        String formattedDate = '';
        if(dateValue != null){
            DateTime dt = DateTime.newInstance(dateValue, Time.newInstance(0, 0, 0, 0));
            formattedDate = dt.format('dd/MM/yyyy');
        }
        return formattedDate;
    }

    public static String newFormattedDate(Date dateValue) {
        String formattedDate = '';
        if (dateValue != null) {
            DateTime dt = DateTime.newInstance(dateValue, Time.newInstance(0, 0, 0, 0));
            formattedDate = dt.format('dd MMM yyyy');
        }
        return formattedDate;
    }


    /**
     * Calculates age in years from a given date of birth.
     * @param dob Date of birth (Date)
     * @return Integer age in years (or -1 if dob is null or in future)
     */
    public static Integer calculateAge(Date dob) {
        if (dob == null || dob > Date.today()) {
            return -1; // or you can throw a custom exception
        }

        Date today = Date.today();
        Integer age = today.year() - dob.year();

        // Adjust if birthday hasn't occurred yet this year
        if (today.month() < dob.month() || 
            (today.month() == dob.month() && today.day() < dob.day())) {
            age--;
        }

        return age;
    }

    public static String resolveLabel(String input, Schema.DescribeFieldResult fieldDesc) {
        if (String.isBlank(input)) return null;
        String trimmed = input.trim();
        for (Schema.PicklistEntry entry : fieldDesc.getPicklistValues()) {
            if (entry.getValue() == trimmed || entry.getLabel() == trimmed) {
                return entry.getLabel();
            }
        }
        return null;
    }
    
    public static String getLabel(String input, SObjectField fieldApiName) {
        return resolveLabel(input, fieldApiName.getDescribe());
    }
    
}