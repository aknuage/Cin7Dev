/**
 * @description       : Queueable class to run custom metadata DML. Used to avoid DML Operation issues
 * @author            : NuAge
 * @last modified on  : 2023-05-10
 * @last modified by  : NuAge
**/
public class NuAge_CustomMetadataQueueable implements Queueable {
    public String fullName; 
    public String label;
    public Map<String, Object> fieldWithValuesMap;

    public NuAge_CustomMetadataQueueable(String fullName, String label, Map<String, Object> fieldWithValuesMap) {
        this.fullName = fullName;
        this.label = label;
        this.fieldWithValuesMap = fieldWithValuesMap;
    }

    public void execute(QueueableContext context) {
        NuAge_CreateUpdateMetadataUtils.CreateUpdateMetadata(fullName, label, fieldWithValuesMap);
    }
}