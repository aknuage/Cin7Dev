/**
 * @description       : 
 * @author            : AS | NuAge Experts
 * @group             : 
 * @last modified on  : 06-12-2023
 * @last modified by  : AS | NuAge Experts
**/
public with sharing class DiscountParse {

    public class Data {
        public String DiscountID;
    }
    
    public Data Data;
    public List<String> Errors;

        
    public static DiscountParse parse(String json) {
        return (DiscountParse) System.JSON.deserialize(json, DiscountParse.class);
    }
}