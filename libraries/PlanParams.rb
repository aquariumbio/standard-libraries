module PlanParams

  # Gets :options from the plan associations and uses it to override default_plan_params
  #
  # @return [Hash] plan_params
  def update_plan_params(plan_params:, opts:)
    if opts.present?
      plan_params.update(parse_options(opts))
    end
    plan_params
  end

  # Parses JSON formatted options
  #
  # @param opts [String] JSON-formatted string
  # @return [Hash]
  def parse_options(opts)
    JSON.parse(opts, { symbolize_names: true })
  end

  # Get Plan options from a list of Operations; checks to to be sure that all 
  #   Operations come from the same Plan
  #
  # @param operations [Array<Operation>] the Operations
  # @return [String] the options
  def strict_plan_options(operations)
    plans = operations.map { |op| op.plan }.uniq

    if plans.length > 1 
      plan_ids = plans.map { |p| p.id }
      msg = "Operations must all be from a single Plan." \
      " #{plan_ids.length} Plans found: #{plan_ids.to_sentence}"
      raise IncompatibleParametersError.new(msg)
    end

    operations.first.plan.associations[:options]
  end
  
  # Gets `:options` from the `Plan` associations and the `Operations` and uses 
  # them to override `default_job_params`
  #
  # @param operations [OperationList] the operations
  # @param default_job_params [Hash] the default parameters to be applied to all 
  #   `Operations` in the `Job`
  # @return [Hash] the updated parameters to be applied to all 
  #   `Operations` in the `Job`
  def update_job_params(operations:, default_job_params:)
    opts = operations.first.plan.associations[:options]
    job_params = update_plan_params(plan_params: default_job_params, opts: opts)
    return job_params unless options_for?(operations)

    job_params.keys.each do |key|
      op_vals = operations.map do |op|
        op.input('Options').val.fetch(key, :no_key)
      end

      if op_vals.uniq.length == 1
        job_params[key] = op_vals.first unless op_vals.first == :no_key
      else
        msg = "More than one value given in Operation Options for #{key}:" \
              " #{op_vals}"
        raise IncompatibleParametersError.new(msg)
      end
    end

    job_params
  end

  # Check to see if any of the `Operations` have `Options` set
  #
  def options_for?(operations)
    operations.any? { |op| op.input('Options').try(:val).present? }
  end

  # Gets `Options` from each `Operation` and uses them to update 
  #   `default_operation_params`, then applies the result to each 
  #   `Operation` at `op.temporary[:options]`
  #
  # @param operations [OperationList] the operations
  # @param default_operation_params [Hash] the default parameters to be applied to all 
  #   `Operations` in the `Job`
  def update_operation_params(operations:, default_operation_params:)
    operations.each do |op|
      opts = default_operation_params.dup.update(op.input('Options').val)
      op.temporary[:options] = opts
    end
  end

  class IncompatibleParametersError < StandardError
  
  end
 
end