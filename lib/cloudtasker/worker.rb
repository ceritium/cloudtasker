# frozen_string_literal: true

module Cloudtasker
  # Cloud Task based workers
  module Worker
    # Add class method to including class
    def self.included(base)
      base.extend(ClassMethods)
      base.attr_accessor :job_args, :job_id
    end

    # Module class methods
    module ClassMethods
      #
      # Set the worker runtime options.
      #
      # @param [Hash] opts The worker options
      #
      # @return [<Type>] <description>
      #
      def cloudtasker_options(opts = {})
        opt_list = opts&.map { |k, v| [k.to_s, v] } || [] # stringify
        @cloudtasker_options_hash = Hash[opt_list]
      end

      #
      # Return the worker runtime options.
      #
      # @return [Hash] The worker runtime options.
      #
      def cloudtasker_options_hash
        @cloudtasker_options_hash
      end

      #
      # Enqueue worker in the backgroundf.
      #
      # @param [Array<any>] *args List of worker arguments
      #
      # @return [Google::Cloud::Tasks::V2beta3::Task] The Google Task response
      #
      def perform_async(*args)
        perform_in(nil, *args)
      end

      #
      # Enqueue worker and delay processing.
      #
      # @param [Integer, nil] interval The delay in seconds.
      # @param [Array<any>] *args List of worker arguments
      #
      # @return [Google::Cloud::Tasks::V2beta3::Task] The Google Task response
      #
      def perform_in(interval, *args)
        schedule(worker: new(job_args: args), interval: interval)
      end

      #
      # Enqueue a worker object, with or without delay.
      #
      # @param [Cloudtasker::Worker] worker The worker to schedule.
      # @param [Integer] interval The delay in seconds.
      #
      # @return [Google::Cloud::Tasks::V2beta3::Task] The Google Task response
      #
      def schedule(worker:, interval: nil)
        Task.new(worker).schedule(interval: interval)
      end
    end

    #
    # Build a new worker instance.
    #
    # @param [Array<any>] job_args The list of perform args.
    # @param [String] job_id A unique ID identifying this job.
    #
    def initialize(job_args: [], job_id: nil)
      @job_args = job_args
      @job_id = job_id || SecureRandom.uuid
    end

    #
    # Execute the worker by calling the `perform` with the args.
    #
    # @return [Any] The result of the perform.
    #
    def execute
      perform(*job_args)
    end

    #
    # Helper method used to re-enqueue the job. Re-enqueued
    # jobs keep the same job_id.
    #
    # This helper may be useful when jobs must pause activity due to external
    # factors such as when a third-party API is throttling the rate of API calls.
    #
    # @param [Integer] interval Delay to wait before processing the job again (in seconds).
    #
    # @return [Google::Cloud::Tasks::V2beta3::Task] The Google Task response
    #
    def reenqueue(interval)
      self.class.schedule(worker: self, interval: interval)
    end
  end
end
