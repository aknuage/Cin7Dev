import { LightningElement, api } from 'lwc';

export default class RecordEditPicklist extends LightningElement {
    @api whatDoYouNeedHelpWith;
    @api whichTopicDoesThisRelateTo;
    @api whatSpecificArea;
    @api classification;
    @api classificationType;

    handleChange1(event) {
        this.whatDoYouNeedHelpWith = event.target.value;
        console.log(this.whatDoYouNeedHelpWith);
    }

    handleChange2(event) {
        this.whichTopicDoesThisRelateTo = event.target.value;
        console.log(this.whichTopicDoesThisRelateTo);
    }

    handleChange3(event) {
        this.whatSpecificArea = event.target.value;
        console.log(this.whatSpecificArea);
    }

    handleChange4(event) {
        this.classification = event.target.value;
        console.log(this.classification);
    }

    handleChange5(event) {
        this.classificationType = event.target.value;
        console.log(this.classificationType);
    }
}