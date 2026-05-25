@isTest
private class NumberToWordsHelperTest {

    @isTest
    static void testConvert() {
        // Arrange
        NumberToWordsHelper helper = new NumberToWordsHelper();
        
        // Test case 1: Convert 0
        helper.numberVal = 0;
        helper.convert();
        System.assertEquals('Zero', helper.wordText, 'Expected Zero for 0');

        // Test case 2: Convert 1
        helper.numberVal = 1;
        helper.convert();
        System.assertEquals('One', helper.wordText, 'Expected One for 1');

        // Test case 3: Convert 15
        helper.numberVal = 15;
        helper.convert();
        System.assertEquals('Fifteen', helper.wordText, 'Expected Fifteen for 15');

        // Test case 4: Convert 20
        helper.numberVal = 20;
        helper.convert();
        System.assertEquals('Twenty', helper.wordText, 'Expected Twenty for 20');

        // Test case 5: Convert 105
        helper.numberVal = 105;
        helper.convert();
        System.assertEquals('One Hundred Five', helper.wordText, 'Expected One Hundred Five for 105');

        // Test case 6: Convert 1000
        helper.numberVal = 1000;
        helper.convert();
        System.assertEquals('One Thousand', helper.wordText, 'Expected One Thousand for 1000');

        // Test case 7: Convert 1000000
        helper.numberVal = 1000000;
        helper.convert();
        System.assertEquals('Ten Lakh', helper.wordText, 'Expected Ten Lakh for 1000000');
    }
}