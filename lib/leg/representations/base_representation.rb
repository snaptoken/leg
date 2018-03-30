module Leg
  module Representations
    class BaseRepresentation
      def initialize(tutorial)
        @tutorial = tutorial
      end

      # Should save @tutorial to disk.
      def save!(options = {})
        raise NotImplementedError
      end

      # Should load @tutorial (in place) from disk, and return it.
      def load!(options = {})
        raise NotImplementedError
      end

      # Returns true if this representation has been modified by the user since the
      # last sync.
      def modified?
        synced_at = @tutorial.last_synced_at
        repr_modified_at = modified_at
        return false if synced_at.nil? or repr_modified_at.nil?

        repr_modified_at > synced_at
      end

      # Returns true if this representation currently exists on disk.
      def exists?
        !modified_at.nil?
      end

      private

      # Should return the Time the representation on disk was last modified, or nil
      # if the representation doesn't exist.
      def modified_at
        raise NotImplementedError
      end
    end
  end
end
