# frozen_string_literal: true

#  Copyright 2023-Present. Couchbase, Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

require "couchbase/stellar_nebula/generated/query.v1_pb"

require "google/protobuf/well_known_types"

module Couchbase
  module StellarNebula
    module RequestGenerator
      class Query
        attr_reader :bucket_name
        attr_reader :scope_name

        def initialize(bucket_name: nil, scope_name: nil)
          @bucket_name = bucket_name
          @scope_name = scope_name
        end

        def query_request(statement, options)
          proto_opts = {}

          bucket_name = @bucket_name
          scope_name = @scope_name
          unless options.scope_qualifier.nil?
            if options.scope_qualifier.include? ":"
              bucket_name, scope_name = options.scope_qualifier.split(":")[1].split(".")
            else
              bucket_name, scope_name = options.scope_qualifier.split(".")
            end
          end
          proto_opts[:scope_name] = scope_name unless scope_name.nil?
          proto_opts[:bucket_name] = bucket_name unless bucket_name.nil?

          proto_opts[:read_only] = options.readonly unless options.readonly.nil?
          proto_opts[:prepared] = !options.adhoc

          tuning_opts = create_tuning_options(options)
          proto_opts[:tuning_options] = tuning_opts unless tuning_opts.nil?

          proto_opts[:client_context_id] = options.client_context_id unless options.client_context_id.nil?
          proto_opts[:scan_consistency] = options.instance_variable_get(:@scan_consistency).upcase unless options.instance_variable_get(:@scan_consistency).nil?
          proto_opts[:positional_parameters] = options.export_positional_parameters unless options.export_positional_parameters.nil?
          proto_opts[:named_parameters] = options.export_named_parameters unless options.export_named_parameters.nil?
          proto_opts[:flex_index] = options.flex_index unless options.flex_index.nil?
          proto_opts[:preserve_expiry] = options.preserve_expiry unless options.preserve_expiry.nil?
          proto_opts[:consistent_with] = options.mutation_state.to_proto unless options.mutation_state.nil?
          proto_opts[:profile_mode] = options.profile.upcase

          Generated::Query::V1::QueryRequest.new(
            statement: statement,
            **proto_opts
          )
        end

        def create_tuning_options(options)
          tuning_opts = {}
          tuning_opts[:max_parallelism] = options.max_parallelism unless options.max_parallelism.nil?
          tuning_opts[:pipeline_batch] = options.pipeline_batch unless options.pipeline_batch.nil?
          tuning_opts[:pipeline_cap] = options.pipeline_cap unless options.pipeline_cap.nil?
          unless options.scan_wait.nil?
            tuning_opts[:scan_wait] = Google::Protobuf::Duration.new(
              {:nanos => (10**6) * Utils::Time.extract_duration(expiry)}
            )
          end
          tuning_opts[:scan_cap] = options.scan_cap unless options.scan_cap.nil?
          tuning_opts[:disable_metrics] = !options.metrics unless options.metrics.nil?
          if tuning_opts.empty?
            nil
          else
            Generated::Query::V1::QueryRequest::TuningOptions.new(**tuning_opts)
          end
        end
      end
    end
  end
end
