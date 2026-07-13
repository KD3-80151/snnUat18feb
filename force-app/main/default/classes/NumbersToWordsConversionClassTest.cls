@isTest
public class NumbersToWordsConversionClassTest {
    
    @isTest
    static void testConvertMethod() {
        NumbersToWordsConversionClass testObj1 = new NumbersToWordsConversionClass();
        testObj1.numberVal = 15;
        testObj1.convert();
        
        NumbersToWordsConversionClass testObj2 = new NumbersToWordsConversionClass();
        testObj2.numberVal = 45;
        testObj2.convert();
        
        NumbersToWordsConversionClass testObj3 = new NumbersToWordsConversionClass();
        testObj3.numberVal = 123;
        testObj3.convert();
        
        NumbersToWordsConversionClass testObj4 = new NumbersToWordsConversionClass();
        testObj4.numberVal = 9876;
        testObj4.convert();
        
        NumbersToWordsConversionClass testObj5 = new NumbersToWordsConversionClass();
        testObj5.numberVal = 123456;
        testObj5.convert();
        
        NumbersToWordsConversionClass testObj6 = new NumbersToWordsConversionClass();
        testObj6.numberVal = 98765432;
        testObj6.convert();
        
        NumbersToWordsConversionClass testObj7 = new NumbersToWordsConversionClass();
        testObj7.numberVal = 0;
        testObj7.convert();
        
        NumbersToWordsConversionClass testObj8 = new NumbersToWordsConversionClass();
        testObj8.numberVal = null;
        testObj8.convert();
    }
    
    @isTest
    static void testNumberToEnglishMethod() {
        System.assertEquals('Fifteen', NumbersToWordsConversionClass.numberToEnglish(15));
        System.assertEquals('Forty Five', NumbersToWordsConversionClass.numberToEnglish(45));
        System.assertEquals('One Hundred Twenty Three', NumbersToWordsConversionClass.numberToEnglish(123));
        System.assertEquals('Nine Thousand Eight Hundred Seventy Six', NumbersToWordsConversionClass.numberToEnglish(9876));
        System.assertEquals('One Lakh Twenty Three Thousand Four Hundred Fifty Six', NumbersToWordsConversionClass.numberToEnglish(123456));
        System.assertEquals('Nine Crore Eighty Seven Lakh Sixty Five Thousand Four Hundred Thirty Two', NumbersToWordsConversionClass.numberToEnglish(98765432));
        System.assertEquals('Zero', NumbersToWordsConversionClass.numberToEnglish(0));
        System.assertEquals('', NumbersToWordsConversionClass.numberToEnglish(null));
    }

    @isTest
    static void testNumberToEnglishDecimalMethod() {
        // Decimal with more than 2 digits, should truncate
        Decimal value1 = 2327.3424;
        String words1 = NumbersToWordsConversionClass.numberToEnglishDecimal(value1);
        System.assertEquals('Two Thousand Three Hundred Twenty Seven and Thirty Four Paisa', words1);

        // Decimal with exactly 2 digits
        Decimal value2 = 15.75;
        String words2 = NumbersToWordsConversionClass.numberToEnglishDecimal(value2);
        System.assertEquals('Fifteen and Seventy Five Paisa', words2);

        // Decimal with 1 digit
        Decimal value3 = 123.4;
        String words3 = NumbersToWordsConversionClass.numberToEnglishDecimal(value3);
        System.assertEquals('One Hundred Twenty Three and Forty Paisa', words3);

        // Decimal with 0 paisa
        Decimal value4 = 500.0;
        String words4 = NumbersToWordsConversionClass.numberToEnglishDecimal(value4);
        System.assertEquals('Five Hundred', words4);

        // Null value
        System.assertEquals('', NumbersToWordsConversionClass.numberToEnglishDecimal(null));
    }
    
    @isTest
    static void testFormatIndianCurrencyMethod() {
        Decimal amount1 = 123.45;
        Decimal amount2 = 1234567.89;
        Decimal amount3 = 0;
        Decimal amount4 = -98765.43;
        
        String formatted1 = NumbersToWordsConversionClass.formatIndianCurrency(amount1);
        String formatted2 = NumbersToWordsConversionClass.formatIndianCurrency(amount2);
        String formatted3 = NumbersToWordsConversionClass.formatIndianCurrency(amount3);
        String formatted4 = NumbersToWordsConversionClass.formatIndianCurrency(amount4);
        
        System.assertNotEquals(null, formatted1);
        System.assertNotEquals(null, formatted2);
        System.assertNotEquals(null, formatted3);
        System.assertNotEquals(null, formatted4);
    }

    @isTest
    static void testFormatIndianCurrencyDecimalMethod() {
        Decimal amount1 = 123.4;        // One decimal place
        Decimal amount2 = 1234567.899;  // More than 2 decimal places
        Decimal amount3 = 98765;        // No decimal
        Decimal amount4 = -5000.5;      // Negative with one decimal

        String formatted1 = NumbersToWordsConversionClass.formatIndianCurrencyDecimal(amount1);
        String formatted2 = NumbersToWordsConversionClass.formatIndianCurrencyDecimal(amount2);
        String formatted3 = NumbersToWordsConversionClass.formatIndianCurrencyDecimal(amount3);
        String formatted4 = NumbersToWordsConversionClass.formatIndianCurrencyDecimal(amount4);

    }
    
    @isTest
    static void testFormattedDateMethod() {
        Date sampleDate = Date.newInstance(2024, 12, 25);
        String formattedDate = NumbersToWordsConversionClass.formattedDate(sampleDate);
        System.assertEquals('25/12/2024', formattedDate);
        System.assertEquals('', NumbersToWordsConversionClass.formattedDate(null));
    }
    
    @isTest
    static void testNewFormattedDateMethod() {
        Date d = Date.newInstance(2024, 12, 25);
        System.assertEquals('25 Dec 2024', NumbersToWordsConversionClass.newFormattedDate(d));
        System.assertEquals('', NumbersToWordsConversionClass.newFormattedDate(null));
    }

    @isTest
    static void testCalculateAgeMethod() {
        Date today = Date.today();
        Integer years = 30;

        Date dobExact = Date.newInstance(today.year() - years, today.month(), today.day());
        System.assertEquals(years, NumbersToWordsConversionClass.calculateAge(dobExact));

        Date dobUpcoming = today.addYears(-years).addMonths(1);
        System.assertEquals(years - 1, NumbersToWordsConversionClass.calculateAge(dobUpcoming));

        Date dobFuture = today.addDays(1);
        System.assertEquals(-1, NumbersToWordsConversionClass.calculateAge(dobFuture));

        System.assertEquals(-1, NumbersToWordsConversionClass.calculateAge(null));
    }

    @isTest
    static void testResolveLabelAndGetLabelMethods() {
        Schema.DescribeFieldResult dfr = Case.Status.getDescribe();
        List<Schema.PicklistEntry> entries = dfr.getPicklistValues();
        System.assert(entries.size() > 0, 'Case.Status must have at least one picklist entry');

        Schema.PicklistEntry anyEntry = entries[0];
        String value = anyEntry.getValue();
        String label = anyEntry.getLabel();

        System.assertEquals(label, NumbersToWordsConversionClass.resolveLabel(value, dfr));
        System.assertEquals(label, NumbersToWordsConversionClass.resolveLabel(label, dfr));

        System.assertEquals(null, NumbersToWordsConversionClass.resolveLabel('', dfr));
        System.assertEquals(null, NumbersToWordsConversionClass.resolveLabel('   ', dfr));

        System.assertEquals(label, NumbersToWordsConversionClass.getLabel(value, Case.Status));
        System.assertEquals(label, NumbersToWordsConversionClass.getLabel(label, Case.Status));
    }
}