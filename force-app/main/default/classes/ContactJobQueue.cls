public class ContactJobQueue {
    public static List<IncomingRequestHelper.ContactJobInputWrapper> jobQueue = new List<IncomingRequestHelper.ContactJobInputWrapper>();

    public static void enqueue(IncomingRequestHelper.ContactJobInputWrapper job) {
        jobQueue.add(job);
    }

    public static IncomingRequestHelper.ContactJobInputWrapper dequeue() {
        if (!jobQueue.isEmpty()) {
            return jobQueue.remove(0); // Simulates polling from a queue
        }
        return null;
    }

    public static Boolean hasJobs() {
        return !jobQueue.isEmpty();
    }
}
