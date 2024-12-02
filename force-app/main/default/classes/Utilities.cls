public class Utilities {
    
    public static void scheduleNext(Schedulable sch, String jobName, integer delay) {
		Datetime nextSchedule = System.now().addSeconds(delay);
		scheduleNext(sch,jobName,nextSchedule);
	}

	public static void scheduleNext(Schedulable sch, String jobName, Datetime triggerTime) {
		String cronFormat = 'ss mm HH dd MM ? yyyy';
		String cronText = triggerTime.format(cronFormat, UserInfo.getTimeZone().getID());
		String schName = jobName + triggerTime.format('yyyyMMddHHmmss');
		System.schedule(schName, cronText, sch);
	}


}